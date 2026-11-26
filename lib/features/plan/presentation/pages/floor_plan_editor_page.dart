import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/domain/repositories/project_repository.dart';
import '../../../home/data/repositories/supabase_project_store.dart';
import '../../../home/domain/entities/project_document.dart';
import '../../../home/domain/repositories/project_store.dart';
import '../../../rules/domain/entities/analysis_input.dart';
import '../../../capture/domain/entities/captured_input.dart';
import '../../../rules/domain/entities/floor_plan_site_analysis.dart';
import '../../../rules/presentation/pages/site_form_page.dart';
import '../../domain/entities/floor_plan.dart';
import '../../domain/entities/floor_plan_data.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import '../widgets/floor_plan_painter.dart';
import 'blueprint_preview_page.dart';
import '../widgets/plan_underlay.dart';
import '../widgets/plan_viewport.dart';

enum _FloorPlanStage { calibrate, lot, rooms }

enum _EditorMode { select, measure }

class FloorPlanEditorPage extends StatefulWidget {
  final FloorPlan initialPlan;
  final String? underlayPath;
  final bool underlayIsPdf;
  final ProjectRepository? projectRepository;
  final String? projectId;
  final BackgroundInfo? background;
  final PlanUnderlay? initialUnderlay;
  final AnalysisInput? analysis;
  final CapturedInput? input;

  const FloorPlanEditorPage({
    super.key,
    required this.initialPlan,
    this.underlayPath,
    this.underlayIsPdf = false,
    this.projectRepository,
    this.projectId,
    this.background,
    this.initialUnderlay,
    this.analysis,
    this.input,
  });

  @override
  State<FloorPlanEditorPage> createState() => _FloorPlanEditorPageState();
}

class _FloorPlanEditorPageState extends State<FloorPlanEditorPage> {
  static const double _hitRadius = 24;
  static const double _snapStepM = 0.05;
  static const int _maxUndo = 50;

  late FloorPlan _plan;
  PlanUnderlay? _underlay;
  PlanViewport? _viewport;
  Size? _canvasSize;
  _FloorPlanStage _stage = _FloorPlanStage.calibrate;
  _EditorMode _mode = _EditorMode.select;
  final List<FloorPlan> _undoStack = [];
  final List<Point2D> _draft = [];
  bool _draftIsLot = false;
  int? _selectedRoom;
  int? _selectedWall;
  int? _selectedVertex;
  List<VertexRef>? _draggedRefs;
  Point2D? _dragStart;
  Point2D? _calibrationStart;
  Point2D? _calibrationEnd;
  Point2D? _measureStart;
  Point2D? _measureEnd;
  bool _isSaving = false;
  ProjectStore? _projectStore;
  ProjectStore get _store => _projectStore ??= SupabaseProjectStore();
  String? _projectId;
  BackgroundInfo? _background;
  BackgroundUpload? _pendingBackground;
  AnalysisInput? _analysis;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan;
    _projectId = widget.projectId;
    _background = widget.background;
    _analysis = widget.analysis;
    if (widget.initialUnderlay != null) {
      _underlay = widget.initialUnderlay;
      _stage = _plan.lot == null ? _FloorPlanStage.lot : _FloorPlanStage.rooms;
    } else {
      _stage = widget.underlayPath == null
          ? (_plan.lot == null ? _FloorPlanStage.lot : _FloorPlanStage.rooms)
          : _FloorPlanStage.calibrate;
      if (widget.underlayPath case final String path) {
        _loadUnderlay(path);
      }
    }
  }

  Future<void> _loadUnderlay(String path) async {
    try {
      final PlanUnderlay loaded = await PlanUnderlay.load(
        path,
        isPdf: widget.underlayIsPdf,
      );
      if (!mounted) {
        loaded.image.dispose();
        return;
      }
      setState(() {
        _underlay = loaded;
        final input = widget.input;
        if (input != null) {
          _pendingBackground = loaded.sourceBytes == null
              ? null
              : BackgroundUpload(
                  bytes: loaded.sourceBytes!,
                  contentType: loaded.contentType,
                );
          _background = BackgroundInfo(
            captureMode: input.mode,
            wasPdf: input.isPdf,
            fileName: input.name,
            storagePath: null,
            originX: loaded.origin.x,
            originY: loaded.origin.y,
            metersPerPixel: loaded.metersPerPixel,
          );
        }
        _viewport = null;
        _canvasSize = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _plan.lot == null
            ? _FloorPlanStage.lot
            : _FloorPlanStage.rooms;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar a referência: $error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _underlay?.image.dispose();
    super.dispose();
  }

  void _pushUndo() {
    _undoStack.add(_plan);
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _plan = _undoStack.removeLast();
      _draft.clear();
      _selectedWall = null;
      _selectedVertex = null;
      _draggedRefs = null;
    });
  }

  PlanViewport _fitViewport(Size size) {
    final PlanUnderlay? image = _underlay;
    final List<Point2D> vertices = _plan.allVertices;
    double minX = image?.origin.x ?? 0;
    double minY = image?.origin.y ?? 0;
    double maxX = image?.widthM ?? 10;
    double maxY = image?.heightM ?? 10;
    if (vertices.isNotEmpty) {
      minX = math.min(minX, vertices.map((p) => p.x).reduce(math.min));
      minY = math.min(minY, vertices.map((p) => p.y).reduce(math.min));
      maxX = math.max(maxX, vertices.map((p) => p.x).reduce(math.max));
      maxY = math.max(maxY, vertices.map((p) => p.y).reduce(math.max));
    }
    return PlanViewport.fitBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      canvasSize: size,
      growth: 1.15,
    );
  }

  Point2D _toMeters(Offset position) =>
      _viewport!.toMeters(position).snapTo(_snapStepM);

  void _onTap(Offset position) {
    final PlanViewport? viewport = _viewport;
    if (viewport == null) return;
    final Point2D point = _stage == _FloorPlanStage.calibrate
        ? viewport.toMeters(position)
        : _toMeters(position);

    if (_stage == _FloorPlanStage.calibrate) {
      _onCalibrationTap(point);
      return;
    }
    if (_mode == _EditorMode.measure) {
      setState(() {
        if (_measureStart == null || _measureEnd != null) {
          _measureStart = point;
          _measureEnd = null;
        } else {
          _measureEnd = point;
        }
      });
      return;
    }
    if (_stage == _FloorPlanStage.lot || _draftIsLot) {
      _onPolygonTap(point, lot: true);
      return;
    }
    if (_draft.isNotEmpty) {
      _onPolygonTap(point, lot: false);
      return;
    }
    _selectAt(position, point);
  }

  void _onCalibrationTap(Point2D point) {
    if (_calibrationStart == null || _calibrationEnd != null) {
      setState(() {
        _calibrationStart = point;
        _calibrationEnd = null;
      });
      return;
    }
    setState(() => _calibrationEnd = point);
    _finishCalibration();
  }

  Future<void> _finishCalibration() async {
    final PlanUnderlay? underlay = _underlay;
    final Point2D? start = _calibrationStart;
    final Point2D? end = _calibrationEnd;
    if (underlay == null || start == null || end == null) return;

    final double imagePixels = start.distanceTo(end) / underlay.metersPerPixel;
    if (imagePixels < 1) {
      _showMessage('Toque em dois pontos diferentes na imagem.');
      setState(() {
        _calibrationStart = null;
        _calibrationEnd = null;
      });
      return;
    }

    final double? distance = await showDialog<double>(
      context: context,
      builder: (_) => const _NumberDialog(
        title: 'Calibrar escala',
        label: 'Distância real entre os pontos',
        suffix: 'm',
      ),
    );
    if (!mounted || distance == null) return;
    final Point2D pivot = underlay.origin;
    setState(() {
      _underlay = PlanUnderlay(
        image: underlay.image,
        origin: pivot,
        metersPerPixel: distance / imagePixels,
        sourceBytes: underlay.sourceBytes,
        contentType: underlay.contentType,
      );
      if (_background != null) {
        _background = _background!.copyWith(
          originX: pivot.x,
          originY: pivot.y,
          metersPerPixel: distance / imagePixels,
        );
      }
      _calibrationStart = null;
      _calibrationEnd = null;
      _viewport = null;
      _canvasSize = null;
      _stage = _plan.lot == null ? _FloorPlanStage.lot : _FloorPlanStage.rooms;
    });
  }

  void _onPolygonTap(Point2D point, {required bool lot}) {
    if (_draft.isNotEmpty &&
        (_viewport!.toCanvas(_draft.first) - _viewport!.toCanvas(point))
                .distance <=
            _hitRadius) {
      _finishPolygon(lot: lot);
      return;
    }
    setState(() {
      if (_draft.isEmpty) _draftIsLot = lot;
      _draft.add(point);
    });
  }

  Future<void> _finishPolygon({required bool lot}) async {
    if (_draft.length < 3) {
      _showMessage('Desenhe pelo menos três pontos para fechar o contorno.');
      return;
    }
    final List<Point2D> vertices = List.of(_draft);
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: lot ? 'Nome do terreno' : 'Nome do cômodo',
        initialValue: lot ? 'Terreno' : 'Cômodo ${_plan.rooms.length + 1}',
      ),
    );
    if (!mounted || name == null) return;

    final Plan polygon = Plan(name: name, vertices: vertices);
    if (polygon.areaM2 <= 0.01) {
      _showMessage('O contorno precisa ter uma área válida.');
      return;
    }
    if (!lot &&
        _plan.lot != null &&
        vertices.any((vertex) => !_plan.lot!.containsPoint(vertex))) {
      _showMessage('Mantenha os vértices do cômodo dentro do terreno.');
      return;
    }

    _pushUndo();
    setState(() {
      _plan = lot ? _plan.withLot(polygon) : _plan.addRoom(polygon);
      _draft.clear();
      _selectedRoom = lot ? null : _plan.rooms.length - 1;
      _selectedWall = null;
      if (lot) _stage = _FloorPlanStage.rooms;
    });
  }

  void _selectAt(Offset position, Point2D point) {
    for (int room = _plan.rooms.length - 1; room >= 0; room--) {
      final Plan candidate = _plan.rooms[room];
      for (int wall = 0; wall < candidate.vertices.length; wall++) {
        if ((_viewport!.toCanvas(candidate.vertices[wall]) - position)
                .distance <=
            _hitRadius) {
          setState(() {
            _selectedRoom = room;
            _selectedWall = null;
            _selectedVertex = wall;
          });
          return;
        }
        final Offset a = _viewport!.toCanvas(candidate.vertices[wall]);
        final Offset b = _viewport!.toCanvas(
          candidate.vertices[(wall + 1) % candidate.vertices.length],
        );
        if (_distanceToSegment(position, a, b) <= 16) {
          setState(() {
            _selectedRoom = room;
            _selectedWall = wall;
            _selectedVertex = null;
          });
          return;
        }
      }
      if (candidate.containsPoint(point)) {
        setState(() {
          _selectedRoom = room;
          _selectedWall = null;
          _selectedVertex = null;
        });
        return;
      }
    }
    setState(() {
      _selectedRoom = null;
      _selectedWall = null;
      _selectedVertex = null;
    });
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final Offset segment = end - start;
    final double lengthSquared = segment.distanceSquared;
    if (lengthSquared == 0) return (point - start).distance;
    final Offset fromStart = point - start;
    final double t =
        (fromStart.dx * segment.dx + fromStart.dy * segment.dy) / lengthSquared;
    final Offset closest = start + segment * t.clamp(0.0, 1.0).toDouble();
    return (point - closest).distance;
  }

  void _onPanStart(DragStartDetails details) {
    if (_stage != _FloorPlanStage.rooms || _mode != _EditorMode.select) return;
    final int? room = _selectedRoom;
    if (room == null) return;
    final Offset position = details.localPosition;
    final Plan selected = _plan.rooms[room];
    for (int index = 0; index < selected.vertices.length; index++) {
      if ((_viewport!.toCanvas(selected.vertices[index]) - position).distance <=
          _hitRadius) {
        final Point2D point = selected.vertices[index];
        final List<VertexRef> refs = _plan.roomVerticesAt(point);
        _draggedRefs = refs.isEmpty ? [VertexRef(room, index)] : refs;
        _dragStart = point;
        _pushUndo();
        return;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final List<VertexRef>? refs = _draggedRefs;
    final Point2D? start = _dragStart;
    if (refs == null || start == null) return;
    final Point2D target = _toMeters(
      _viewport!.toCanvas(start) + details.delta,
    );
    setState(() => _plan = _plan.moveVertices(refs, target));
  }

  void _onPanEnd(DragEndDetails details) {
    _draggedRefs = null;
    _dragStart = null;
  }

  Future<void> _editSelectedWall() async {
    final int? roomIndex = _selectedRoom;
    final int? wallIndex = _selectedWall;
    if (roomIndex == null || wallIndex == null) return;
    final Plan room = _plan.rooms[roomIndex];
    final double? length = await showDialog<double>(
      context: context,
      builder: (_) => _NumberDialog(
        title: 'Comprimento da parede',
        label: 'Nova medida',
        suffix: 'm',
        initialValue: room.walls[wallIndex].lengthM,
      ),
    );
    if (!mounted || length == null) return;
    _pushUndo();
    setState(() {
      _plan = _plan.setRoomWallLength(roomIndex, wallIndex, length);
      _viewport = null;
      _canvasSize = null;
    });
  }

  void _insertSelectedCorner() {
    final int? roomIndex = _selectedRoom;
    final int? wallIndex = _selectedWall;
    if (roomIndex == null || wallIndex == null) return;
    final Plan room = _plan.rooms[roomIndex];
    final Point2D start = room.vertices[wallIndex];
    final Point2D end = room.vertices[(wallIndex + 1) % room.vertices.length];
    _pushUndo();
    setState(() {
      _plan = _plan.replaceRoom(
        roomIndex,
        room.insertVertexOnWall(
          wallIndex,
          Point2D((start.x + end.x) / 2, (start.y + end.y) / 2),
        ),
      );
      _selectedVertex = wallIndex + 1;
      _selectedWall = null;
    });
  }

  void _removeSelectedCorner() {
    final int? roomIndex = _selectedRoom;
    final int? vertexIndex = _selectedVertex;
    if (roomIndex == null || vertexIndex == null) return;
    if (_plan.rooms[roomIndex].vertices.length <= 3) {
      _showMessage('Um cômodo precisa de pelo menos três cantos.');
      return;
    }
    final Point2D point = _plan.rooms[roomIndex].vertices[vertexIndex];
    if (_plan.roomVerticesAt(point).length > 1) {
      _showMessage('Não é possível remover um canto compartilhado.');
      return;
    }
    _pushUndo();
    setState(() {
      _plan = _plan.replaceRoom(
        roomIndex,
        _plan.rooms[roomIndex].removeVertex(vertexIndex),
      );
      _selectedVertex = null;
    });
  }

  Future<void> _renameSelectedRoom() async {
    final int? index = _selectedRoom;
    if (index == null) return;
    final Plan room = _plan.rooms[index];
    final String? name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NameDialog(title: 'Renomear cômodo', initialValue: room.name),
    );
    if (!mounted || name == null) return;
    _pushUndo();
    setState(() => _plan = _plan.replaceRoom(index, room.copyWith(name: name)));
  }

  void _removeSelectedRoom() {
    final int? index = _selectedRoom;
    if (index == null) return;
    _pushUndo();
    setState(() {
      _plan = _plan.removeRoom(index);
      _selectedRoom = null;
      _selectedWall = null;
    });
  }

  void _startDrawingRoom() {
    if (_plan.lot == null) {
      _showMessage('Desenhe o terreno antes dos cômodos.');
      setState(() => _stage = _FloorPlanStage.lot);
      return;
    }
    setState(() {
      _stage = _FloorPlanStage.rooms;
      _draftIsLot = false;
      _draft.clear();
      _selectedRoom = null;
      _selectedWall = null;
    });
  }

  void _startDrawingLot() {
    setState(() {
      _stage = _FloorPlanStage.lot;
      _draftIsLot = true;
      _draft.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAnalysis() async {
    if (_plan.rooms.isEmpty) {
      _showMessage('Adicione ao menos um cômodo para continuar.');
      return;
    }
    if (_plan.lot == null) {
      _showMessage('Desenhe o terreno antes de analisar.');
      return;
    }
    final FloorPlanSiteAnalysis analysis = FloorPlanSiteAnalysis.fromFloorPlan(
      _plan,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SiteFormPage(
          plan: analysis.building,
          floorPlan: _plan,
          initialSite: _analysis?.site ?? analysis.site,
          initialSettings: _analysis?.settings,
          onAnalysisChanged: _onAnalysisChanged,
        ),
      ),
    );
  }

  void _onAnalysisChanged(AnalysisInput analysis) {
    setState(() => _analysis = analysis);
    final id = _projectId;
    if (id != null) _store.saveAnalysis(id, analysis).catchError((_) {});
  }

  BackgroundInfo? _backgroundForSave() {
    final underlay = _underlay;
    final background = _background;
    if (underlay == null || background == null) return background;
    return background.copyWith(
      originX: underlay.origin.x,
      originY: underlay.origin.y,
      metersPerPixel: underlay.metersPerPixel,
    );
  }

  Future<void> _saveProject() async {
    if (_isSaving || _plan.rooms.isEmpty) return;
    FloorPlan plan = _plan;
    if (_projectId == null) {
      final String? name = await showDialog<String>(
        context: context,
        builder: (_) =>
            _NameDialog(title: 'Salvar projeto', initialValue: _plan.name),
      );
      if (!mounted || name == null) return;
      if (name.length > 120) {
        _showMessage('O nome pode ter no máximo 120 caracteres.');
        return;
      }
      plan = _plan.withName(name);
    }
    setState(() => _isSaving = true);
    try {
      final saved = await _store.save(
        projectId: _projectId,
        floorPlan: plan,
        background: _backgroundForSave(),
        pendingBackground: _pendingBackground,
        analysis: _analysis,
      );
      if (!mounted) return;
      setState(() {
        _projectId = saved.id;
        _plan = plan;
        _background = saved.document.background;
        _isSaving = false;
        if (!saved.backgroundUploadFailed) _pendingBackground = null;
      });
      _showMessage(
        saved.backgroundUploadFailed
            ? 'Projeto salvo, mas a imagem não foi enviada. Toque em salvar para tentar novamente.'
            : 'Projeto salvo!',
      );
    } on PostgrestException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(
        'Não foi possível salvar. Verifique sua conexão e tente novamente.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Não foi possível salvar o projeto.');
    }
  }

  Future<void> _useCalibrationWithoutScale() async {
    if (_underlay == null) return;
    setState(() {
      _stage = _plan.lot == null ? _FloorPlanStage.lot : _FloorPlanStage.rooms;
      _calibrationStart = null;
      _calibrationEnd = null;
    });
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? AppColors.highlight : null,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.name),
        actions: [
          IconButton(
            tooltip: 'Ver desenho técnico',
            onPressed: _plan.hasRooms ? _openBlueprint : null,
            icon: const Icon(Icons.architecture_outlined),
          ),
          IconButton(
            tooltip: 'Desfazer',
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          if (widget.projectRepository != null || _projectId != null)
            IconButton(
              tooltip: 'Salvar projeto',
              onPressed: _isSaving ? null : _saveProject,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildInstruction(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size size = constraints.biggest;
                if (_viewport == null || _canvasSize != size) {
                  _canvasSize = size;
                  _viewport = _fitViewport(size);
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _onTap(details.localPosition),
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: size,
                    painter: FloorPlanPainter(
                      plan: _plan,
                      viewport: _viewport!,
                      underlay: _underlay,
                      selectedRoom: _selectedRoom,
                      selectedWall: _selectedWall,
                      draggedPoint: _dragStart,
                      draft: _draft,
                      draftIsLot: _draftIsLot,
                      measureStart: _measureStart,
                      measureEnd: _measureEnd,
                      calibrateStart: _calibrationStart,
                      calibrateEnd: _calibrationEnd,
                    ),
                  ),
                );
              },
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  void _openBlueprint() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlueprintPreviewPage(
          data: FloorPlanData(plan: _plan.withLot(null)),
          title: _plan.name,
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    final String instruction = switch (_stage) {
      _FloorPlanStage.calibrate => 'Toque em dois pontos conhecidos da planta.',
      _FloorPlanStage.lot =>
        _draft.isEmpty
            ? 'Toque nos cantos do terreno; toque no primeiro para fechar.'
            : 'Continue marcando o terreno e toque no primeiro ponto para fechar.',
      _FloorPlanStage.rooms =>
        _draft.isNotEmpty
            ? 'Marque os cantos do cômodo e toque no primeiro para fechar.'
            : 'Selecione um cômodo ou comece a desenhar outro.',
    };
    return Container(
      width: double.infinity,
      color: AppColors.highlight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        instruction,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildControls() {
    final int? room = _selectedRoom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_stage == _FloorPlanStage.calibrate)
              Row(
                children: [
                  _buildToolButton(
                    icon: Icons.skip_next,
                    label: 'Pular escala',
                    onPressed: _useCalibrationWithoutScale,
                  ),
                  _buildToolButton(
                    icon: Icons.restart_alt,
                    label: 'Reiniciar pontos',
                    onPressed: () => setState(() {
                      _calibrationStart = null;
                      _calibrationEnd = null;
                    }),
                  ),
                ],
              )
            else if (_draft.isNotEmpty)
              Row(
                children: [
                  _buildToolButton(
                    icon: Icons.check,
                    label: 'Fechar contorno',
                    onPressed: () => _finishPolygon(lot: _draftIsLot),
                  ),
                  _buildToolButton(
                    icon: Icons.backspace_outlined,
                    label: 'Desfazer ponto',
                    onPressed: () => setState(() => _draft.removeLast()),
                  ),
                  _buildToolButton(
                    icon: Icons.close,
                    label: 'Cancelar',
                    onPressed: () => setState(() => _draft.clear()),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  _buildToolButton(
                    icon: Icons.landscape_outlined,
                    label: 'Terreno',
                    selected: _stage == _FloorPlanStage.lot,
                    onPressed: _startDrawingLot,
                  ),
                  _buildToolButton(
                    icon: Icons.add_home_work_outlined,
                    label: 'Adicionar cômodo',
                    onPressed: _startDrawingRoom,
                  ),
                  _buildToolButton(
                    icon: Icons.straighten,
                    label: 'Medir',
                    selected: _mode == _EditorMode.measure,
                    onPressed: () => setState(() {
                      _mode = _mode == _EditorMode.measure
                          ? _EditorMode.select
                          : _EditorMode.measure;
                      _measureStart = null;
                      _measureEnd = null;
                    }),
                  ),
                ],
              ),
              if (room != null)
                Row(
                  children: [
                    _buildToolButton(
                      icon: Icons.edit_outlined,
                      label: 'Renomear',
                      onPressed: _renameSelectedRoom,
                    ),
                    _buildToolButton(
                      icon: Icons.straighten,
                      label: 'Editar parede',
                      onPressed: _selectedWall == null
                          ? () => _showMessage(
                              'Toque em uma parede para selecioná-la.',
                            )
                          : _editSelectedWall,
                    ),
                    _buildToolButton(
                      icon: Icons.add_location_alt_outlined,
                      label: 'Adicionar canto',
                      onPressed: _selectedWall == null
                          ? () => _showMessage(
                              'Toque em uma parede para selecionar onde '
                              'adicionar o canto.',
                            )
                          : _insertSelectedCorner,
                    ),
                    _buildToolButton(
                      icon: Icons.remove_circle_outline,
                      label: 'Remover canto',
                      onPressed: _selectedVertex == null
                          ? () => _showMessage(
                              'Toque em um canto para selecioná-lo.',
                            )
                          : _removeSelectedCorner,
                    ),
                  ],
                ),
              if (room != null)
                Row(
                  children: [
                    _buildToolButton(
                      icon: Icons.delete_outline,
                      label: 'Remover cômodo',
                      onPressed: _removeSelectedRoom,
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_plan.rooms.length} cômodo(s) • '
                      '${formatDecimal(_plan.builtAreaM2)} m² construídos',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton(
                    onPressed: _openAnalysis,
                    child: const Text('Analisar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _NameDialog({required this.title, required this.initialValue});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nome'),
        maxLength: 120,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final String value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _NumberDialog extends StatefulWidget {
  final String title;
  final String label;
  final String suffix;
  final double? initialValue;

  const _NumberDialog({
    required this.title,
    required this.label,
    required this.suffix,
    this.initialValue,
  });

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue == null
        ? ''
        : formatDecimal(widget.initialValue!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffix,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final double? value = double.tryParse(
              _controller.text.trim().replaceAll(',', '.'),
            );
            if (value == null || !value.isFinite || value <= 0) {
              setState(() => _error = 'Informe um valor maior que zero.');
              return;
            }
            Navigator.pop(context, value);
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
