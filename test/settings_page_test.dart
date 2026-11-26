import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smartfloor/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('exibe preferências e atualiza os valores selecionados', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SettingsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(controller: controller, onAdd: _noop),
      ),
    );

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Metros (m)'), findsOneWidget);
    expect(find.text('Alta (HD)'), findsOneWidget);
    expect(find.text('Privacidade e permissões'), findsOneWidget);

    await tester.tap(find.text('Pés'));
    await tester.pumpAndSettle();
    expect(find.text('Pés (ft)'), findsOneWidget);

    await tester.tap(find.text('Baixa'));
    await tester.pumpAndSettle();
    expect(controller.captureQuality, CaptureQuality.low);
    expect(find.text('Baixa'), findsNWidgets(2));
    expect(find.text('Alta (HD)'), findsNothing);

    final savingSwitch = tester.widget<Switch>(find.byType(Switch).first);
    expect(savingSwitch.value, isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Desativado'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do SmartFloor?'), findsOneWidget);
    expect(find.text('Ação de saída ainda não configurada.'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('confirma a saída pelo callback fornecido', (tester) async {
    var signOutCalled = false;
    var addCalled = false;
    final controller = SettingsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          controller: controller,
          onAdd: () => addCalled = true,
          onSignOut: () async => signOutCalled = true,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Nova captura'));
    expect(addCalled, isTrue);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair').last);
    await tester.pumpAndSettle();

    expect(signOutCalled, isTrue);
  });

  testWidgets('rolagem permite usar a tela em uma janela compacta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SettingsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(controller: controller, onAdd: _noop),
      ),
    );

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
