import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/ar_measurement_controller.dart';
import '../../domain/entities/ar_room_measurements.dart';

class GuidedArScanPage extends StatefulWidget {
  final ArMeasurementController? controller;

  const GuidedArScanPage({super.key, this.controller});

  @override
  State<GuidedArScanPage> createState() => _GuidedArScanPageState();
}

class _GuidedArScanPageState extends State<GuidedArScanPage>
    with WidgetsBindingObserver {
  static const _steps = ['Largura', 'Comprimento', 'Altura'];

  late final ArMeasurementController _controller =
      widget.controller ?? MethodChannelArMeasurementController();
  StreamSubscription<ArMeasurementEvent>? _eventSubscription;
  final List<List<double>> _points = [];
  final List<double> _measurements = [];
  String _availability = 'checking';
  String _trackingState = 'paused';
  String _instruction = 'Preparando a câmera...';
  String? _errorMessage;
  bool _isStarting = false;
  bool _sessionStarted = false;

  int get _stepIndex => _measurements.length;
  String get _currentStep => _steps[_stepIndex];

  double? get _currentMeasurement {
    if (_points.length != 2) return null;
    final dx = _points[1][0] - _points[0][0];
    final dy = _points[1][1] - _points[0][1];
    final dz = _points[1][2] - _points[0][2];
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventSubscription = _controller.events.listen(
      _onEvent,
      onError: (Object error) {
        if (mounted) {
          setState(() => _errorMessage = 'Falha na leitura do AR: $error');
        }
      },
    );
    unawaited(_prepare());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_eventSubscription?.cancel());
    if (_sessionStarted) unawaited(_controller.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_sessionStarted) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.resume());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_controller.pause());
    }
  }

  Future<void> _prepare() async {
    if (mounted) {
      setState(() {
        _availability = 'checking';
        _errorMessage = null;
        _instruction = 'Verificando compatibilidade do aparelho...';
      });
    }
    try {
      final availability = await _controller.checkAvailability();
      if (!mounted) return;
      if (availability != 'supported') {
        setState(() {
          _availability = availability;
          _instruction = availability == 'needsInstall'
              ? 'Instale o Google Play Services para RA para continuar.'
              : 'Este aparelho não está disponível para medição ARCore.';
        });
        return;
      }

      final hasPermission = await _controller.requestCameraPermission();
      if (!mounted) return;
      if (!hasPermission) {
        setState(() {
          _availability = 'permissionDenied';
          _instruction = 'A permissão da câmera é necessária para medir.';
        });
        return;
      }
      setState(() {
        _availability = 'ready';
        _instruction = 'Aponte para o chão e marque o primeiro ponto.';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _availability = 'error';
        _errorMessage = error.message ?? error.code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _availability = 'error';
        _errorMessage = 'Não foi possível preparar o escaneamento: $error';
      });
    }
  }

  Future<void> _requestInstall() async {
    try {
      final installed = await _controller.requestInstall();
      if (!mounted) return;
      if (installed) {
        await _prepare();
      } else {
        setState(() {
          _instruction =
              'Conclua a instalação do Google Play Services para RA e tente novamente.';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message ?? error.code);
    }
  }

  Future<void> _onPlatformViewCreated(int id) async {
    if (_isStarting) return;
    _isStarting = true;
    try {
      await _controller.start();
      if (!mounted) return;
      setState(() {
        _sessionStarted = true;
        _instruction = 'Mova o celular devagar e toque no primeiro ponto.';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _availability = 'error';
        _errorMessage = error.message ?? error.code;
      });
    } finally {
      _isStarting = false;
    }
  }

  void _onEvent(ArMeasurementEvent event) {
    if (!mounted) return;
    if (event.type == 'tracking') {
      setState(() {
        _trackingState = event.trackingState ?? 'paused';
        if (_trackingState == 'tracking') _errorMessage = null;
      });
    } else if (event.type == 'point') {
      final position = event.position;
      if (position == null || position.length != 3) return;
      setState(() {
        _errorMessage = null;
        if (_points.length < 2) _points.add(position);
        _instruction = _points.length == 1
            ? 'Ponto 1 marcado. Toque no segundo ponto de $_currentStep.'
            : 'Medida estimada pronta para revisão.';
      });
    } else if (event.type == 'tapFailed') {
      setState(() => _instruction =
          event.message ?? 'Não encontrei uma superfície. Tente novamente.');
    } else if (event.type == 'error') {
      setState(() => _errorMessage =
          event.message ?? 'Ocorreu um erro durante o escaneamento.');
    }
  }

  void _confirmMeasurement() {
    final measurement = _currentMeasurement;
    if (measurement == null || !measurement.isFinite || measurement <= 0) {
      return;
    }
    if (measurement > 100) {
      setState(() {
        _points.clear();
        _instruction = 'A medida passou de 100 m. Marque os pontos novamente.';
      });
      return;
    }

    final updatedMeasurements = [..._measurements, measurement];
    if (updatedMeasurements.length == _steps.length) {
      Navigator.of(context).pop(
        ArRoomMeasurements(
          widthM: updatedMeasurements[0],
          lengthM: updatedMeasurements[1],
          heightM: updatedMeasurements[2],
        ),
      );
      return;
    }

    setState(() {
      _measurements.add(measurement);
      _points.clear();
      _instruction = updatedMeasurements.length == 2
          ? 'Aponte para a parede e marque o ponto mais baixo da altura.'
          : 'Aponte para o chão e marque o primeiro ponto do comprimento.';
    });
  }

  Future<void> _capturePoint() async {
    if (!_sessionStarted || _trackingState != 'tracking') {
      setState(() {
        _instruction =
            'Aguarde o AR localizar a superfície e tente tocar novamente.';
      });
      return;
    }
    try {
      await _controller.capturePoint();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _instruction =
            error.message ?? 'Não foi possível marcar esse ponto.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Medir ambiente'),
      ),
      body: _availability == 'ready'
          ? _buildScanner()
          : _buildAvailabilityMessage(),
    );
  }

  Widget _buildAvailabilityMessage() {
    final message = _errorMessage ?? _instruction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_availability == 'checking')
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.view_in_ar_outlined,
                color: Colors.white,
                size: 48,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (_availability == 'needsInstall')
              FilledButton(
                onPressed: _requestInstall,
                child: const Text('Instalar / atualizar ARCore'),
              )
            else if (_availability == 'permissionDenied')
              FilledButton(
                onPressed: _prepare,
                child: const Text('Permitir câmera'),
              )
            else if (_availability == 'error')
              FilledButton(
                onPressed: _prepare,
                child: const Text('Tentar novamente'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao preenchimento manual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    final measurement = _currentMeasurement;
    return Stack(
      fit: StackFit.expand,
      children: [
        AndroidView(
          viewType: 'smartfloor/ar_measurement_view',
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: _ScannerCard(
            title: '${_currentStep} • Etapa ${_stepIndex + 1} de 3',
            message: _errorMessage ?? _instruction,
            trackingState: _trackingState,
            pointsMarked: _points.length,
          ),
        ),
        const IgnorePointer(
          child: Center(
            child: Icon(Icons.add, color: Colors.white, size: 34),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (measurement != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Estimativa: ${measurement.toStringAsFixed(2)} m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _points.isEmpty
                            ? null
                            : () => setState(() {
                                  _points.clear();
                                  _instruction =
                                      'Marque novamente os dois pontos de $_currentStep.';
                                }),
                        child: const Text('Refazer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: measurement == null
                            ? _capturePoint
                            : _confirmMeasurement,
                        child: Text(
                          measurement == null
                              ? _points.isEmpty
                                  ? 'Marcar ponto 1'
                                  : 'Marcar ponto 2'
                              : _stepIndex == _steps.length - 1
                                  ? 'Usar medidas'
                                  : 'Confirmar $_currentStep',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Medidas aproximadas: confira e ajuste no formulário.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerCard extends StatelessWidget {
  final String title;
  final String message;
  final String trackingState;
  final int pointsMarked;

  const _ScannerCard({
    required this.title,
    required this.message,
    required this.trackingState,
    required this.pointsMarked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.78),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  trackingState == 'tracking' ? 'AR ativo' : 'Localizando...',
                  style: TextStyle(
                    color: trackingState == 'tracking'
                        ? AppColors.highlight
                        : Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: Colors.white)),
            Text(
              'Pontos marcados: $pointsMarked de 2',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
