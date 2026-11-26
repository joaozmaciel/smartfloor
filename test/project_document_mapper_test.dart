import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/capture/domain/entities/capture_mode.dart';
import 'package:smartfloor/features/home/data/project_document_mapper.dart';
import 'package:smartfloor/features/home/domain/entities/project_document.dart';
import 'package:smartfloor/features/plan/domain/entities/floor_plan.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/rules/domain/entities/analysis_input.dart';
import 'package:smartfloor/features/rules/domain/entities/rule_settings.dart';
import 'package:smartfloor/features/rules/domain/entities/site.dart';

ProjectDocument roundTrip(ProjectDocument value) =>
    ProjectDocumentMapper.fromJson(
      jsonDecode(jsonEncode(ProjectDocumentMapper.toJson(value)))
          as Map<String, dynamic>,
    );

void main() {
  test('preserva terreno, cômodos e ordem dos vértices', () {
    final plan = FloorPlan(
      name: 'Casa',
      lot: Plan.rectangle(name: 'Lote', widthM: 12, lengthM: 20),
      rooms: [
        Plan.rectangle(name: 'Sala', widthM: 4, lengthM: 3),
        Plan(
          name: 'Quarto',
          vertices: const [
            Point2D(4, 0),
            Point2D(7, 0),
            Point2D(7, 3),
            Point2D(4, 3),
          ],
        ),
      ],
    );
    final restored = roundTrip(ProjectDocument(floorPlan: plan)).floorPlan;
    expect(restored.lot!.vertices.first.x, 0);
    expect(restored.rooms[1].vertices.first.x, 4);
    expect(restored.builtAreaM2, 21);
    expect(restored.rooms.map((room) => room.name), ['Sala', 'Quarto']);
  });

  test('preserva imagem e calibração', () {
    final document = ProjectDocument(
      floorPlan: const FloorPlan(name: 'Casa'),
      background: const BackgroundInfo(
        captureMode: CaptureMode.imageOrPdf,
        wasPdf: true,
        fileName: 'planta.pdf',
        storagePath: 'u/p/background',
        originX: 2,
        originY: 3,
        metersPerPixel: 0.02,
      ),
    );
    final background = roundTrip(document).background!;
    expect(background.storagePath, 'u/p/background');
    expect(background.originX, 2);
    expect(background.originY, 3);
    expect(background.metersPerPixel, 0.02);
    expect(background.captureMode, CaptureMode.imageOrPdf);
    expect(background.wasPdf, isTrue);
  });

  test('preserva entradas de análise', () {
    final input = AnalysisInput(
      site: const Site(
        widthM: 10,
        lengthM: 20,
        frontSetbackM: 5,
        leftSetbackM: 1,
      ),
      settings: const RuleSettings(
        minFrontSetbackM: 2,
        minSideSetbackM: 1,
        minRearSetbackM: 3,
        maxOccupancyPercent: 50,
      ),
    );
    final restored = roundTrip(
      ProjectDocument(
        floorPlan: const FloorPlan(name: 'Casa'),
        analysis: input,
      ),
    ).analysis!;
    expect(restored.site.widthM, 10);
    expect(restored.site.frontSetbackM, 5);
    expect(restored.settings.maxOccupancyPercent, 50);
  });

  test('aceita ausência de terreno, imagem e análise', () {
    final result = roundTrip(
      ProjectDocument(floorPlan: const FloorPlan(name: 'Vazio')),
    );
    expect(result.floorPlan.lot, isNull);
    expect(result.background, isNull);
    expect(result.analysis, isNull);
  });

  test('recusa versão desconhecida', () {
    expect(
      () => ProjectDocumentMapper.fromJson({'version': 2}),
      throwsFormatException,
    );
  });

  test('recusa polígono curto', () {
    expect(
      () => ProjectDocumentMapper.fromJson({
        'version': 1,
        'floorPlan': {
          'name': 'x',
          'lot': null,
          'rooms': [
            {
              'name': 'x',
              'vertices': [
                {'x': 0, 'y': 0},
                {'x': 1, 'y': 0},
              ],
            },
          ],
        },
      }),
      throwsFormatException,
    );
  });
}
