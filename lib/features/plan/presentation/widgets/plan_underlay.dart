import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:printing/printing.dart';

import '../../domain/entities/point_2d.dart';

/// Imagem de referência posicionada no mesmo sistema de coordenadas em metros.
class PlanUnderlay {
  final ui.Image image;
  final Point2D origin;
  final double metersPerPixel;
  final Uint8List? sourceBytes;
  final String contentType;

  const PlanUnderlay({
    required this.image,
    required this.origin,
    required this.metersPerPixel,
    this.sourceBytes,
    this.contentType = 'image/png',
  });

  double get widthM => image.width * metersPerPixel;
  double get heightM => image.height * metersPerPixel;

  PlanUnderlay scaledAbout(Point2D pivot, double factor) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(factor, 'factor', 'Deve ser maior que zero.');
    }
    return PlanUnderlay(
      image: image,
      origin: Point2D(
        pivot.x + (origin.x - pivot.x) * factor,
        pivot.y + (origin.y - pivot.y) * factor,
      ),
      metersPerPixel: metersPerPixel * factor,
      sourceBytes: sourceBytes,
      contentType: contentType,
    );
  }

  static Future<PlanUnderlay> load(String path, {required bool isPdf}) async {
    Uint8List bytes = await File(path).readAsBytes();
    if (isPdf) {
      bool rendered = false;
      await for (final PdfRaster page in Printing.raster(
        bytes,
        pages: const [0],
        dpi: 100,
      )) {
        bytes = await page.toPng();
        rendered = true;
        break;
      }
      if (!rendered) {
        throw const FormatException('O PDF não possui uma primeira página.');
      }
    }

    return fromBytes(bytes);
  }

  static Future<PlanUnderlay> fromBytes(
    Uint8List bytes, {
    Point2D origin = const Point2D(0, 0),
    double? metersPerPixel,
    bool keepBytes = true,
  }) async {
    String type = _contentType(bytes);
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1800,
      allowUpscaling: false,
    );
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      Uint8List? retained = keepBytes ? bytes : null;
      if (retained != null && retained.length > 9 * 1024 * 1024) {
        final ByteData? png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png != null) {
          retained = png.buffer.asUint8List(
            png.offsetInBytes,
            png.lengthInBytes,
          );
          type = 'image/png';
        }
      }
      return PlanUnderlay(
        image: frame.image,
        origin: origin,
        metersPerPixel: metersPerPixel ?? 20 / frame.image.width,
        sourceBytes: retained,
        contentType: type,
      );
    } finally {
      codec.dispose();
    }
  }

  static String _contentType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47)
      return 'image/png';
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff)
      return 'image/jpeg';
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
      return 'image/webp';
    return 'image/png';
  }
}
