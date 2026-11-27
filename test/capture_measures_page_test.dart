import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/capture/data/ar_measurement_controller.dart';
import 'package:smartfloor/features/capture/domain/entities/capture_mode.dart';
import 'package:smartfloor/features/capture/domain/entities/captured_input.dart';
import 'package:smartfloor/features/capture/presentation/pages/capture_measures_page.dart';
import 'package:smartfloor/features/plan/presentation/pages/floor_plan_editor_page.dart';

class _UnsupportedArMeasurementController
    implements ArMeasurementController {
  @override
  Stream<ArMeasurementEvent> get events => const Stream.empty();

  @override
  Future<String> checkAvailability() async => 'unsupported';

  @override
  Future<bool> requestCameraPermission() async => false;

  @override
  Future<bool> requestInstall() async => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> capturePoint() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  const input = CapturedInput(
    path: 'C:/planta.pdf',
    name: 'planta.pdf',
    mode: CaptureMode.imageOrPdf,
  );

  testWidgets('shows area estimate and opens the plan editor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CaptureMeasuresPage(input: input)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Meio ambiente');
    await tester.enterText(find.byType(TextFormField).at(1), '3,5');
    await tester.enterText(find.byType(TextFormField).at(2), '2');
    await tester.enterText(find.byType(TextFormField).at(3), '2,8');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Área estimada: 7,00 m²'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Área estimada: 7,00 m²'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(FloorPlanEditorPage), findsOneWidget);
    expect(find.textContaining('7,00 m²'), findsOneWidget);
    expect(find.text('Adicionar cômodo'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('validates required fields and measure limits', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CaptureMeasuresPage(input: input)),
    );

    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Informe um número válido'), findsNWidgets(3));

    await tester.enterText(find.byType(TextFormField).at(0), 'Meio ambiente');
    await tester.enterText(find.byType(TextFormField).at(1), '101');
    await tester.enterText(find.byType(TextFormField).at(2), '-1');
    await tester.enterText(find.byType(TextFormField).at(3), '2,8');
    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Máximo de 100 m'), findsOneWidget);
    expect(find.text('Deve ser maior que zero'), findsOneWidget);
  });

  testWidgets('ARCore unsupported devices can return to manual entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureMeasuresPage(
          input: input,
          arMeasurementController: _UnsupportedArMeasurementController(),
        ),
      ),
    );

    await tester.tap(find.text('Preencher com escaneamento AR'));
    await tester.pumpAndSettle();

    expect(
      find.text('Este aparelho não está disponível para medição ARCore.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voltar ao preenchimento manual'));
    await tester.pumpAndSettle();

    expect(find.text('Medidas do ambiente'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });
}
