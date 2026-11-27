import 'plan.dart';
import 'point_2d.dart';

class VertexRef {
  final int owner;
  final int index;

  const VertexRef(this.owner, this.index);

  bool get isLot => owner == FloorPlan.lotOwner;
}

/// Modelo imutável do terreno e dos cômodos desenhados.
class FloorPlan {
  static const int lotOwner = -1;

  final String name;
  final Plan? lot;
  final List<Plan> rooms;

  const FloorPlan({required this.name, this.lot, this.rooms = const []});

  FloorPlan withName(String newName) =>
      FloorPlan(name: newName, lot: lot, rooms: rooms);

  FloorPlan withLot(Plan? newLot) =>
      FloorPlan(name: name, lot: newLot, rooms: rooms);

  FloorPlan addRoom(Plan room) =>
      FloorPlan(name: name, lot: lot, rooms: [...rooms, room]);

  FloorPlan replaceRoom(int index, Plan room) {
    final List<Plan> updated = List.of(rooms);
    updated[index] = room;
    return FloorPlan(name: name, lot: lot, rooms: updated);
  }

  FloorPlan removeRoom(int index) {
    final List<Plan> updated = List.of(rooms)..removeAt(index);
    return FloorPlan(name: name, lot: lot, rooms: updated);
  }

  Point2D vertexAt(VertexRef ref) => ref.isLot
      ? lot!.vertices[ref.index]
      : rooms[ref.owner].vertices[ref.index];

  List<VertexRef> roomVerticesAt(Point2D point, {double toleranceM = 0.01}) {
    final List<VertexRef> result = [];
    for (int room = 0; room < rooms.length; room++) {
      for (int vertex = 0; vertex < rooms[room].vertices.length; vertex++) {
        if (rooms[room].vertices[vertex].distanceTo(point) <= toleranceM) {
          result.add(VertexRef(room, vertex));
        }
      }
    }
    return result;
  }

  FloorPlan moveVertices(Iterable<VertexRef> refs, Point2D to) {
    Plan? newLot = lot;
    final List<Plan> newRooms = List.of(rooms);
    for (final VertexRef ref in refs) {
      if (ref.isLot) {
        final Plan? currentLot = newLot;
        if (currentLot == null) {
          throw StateError('Não há terreno para mover este vértice.');
        }
        newLot = currentLot.moveVertex(ref.index, to);
      } else {
        newRooms[ref.owner] = newRooms[ref.owner].moveVertex(ref.index, to);
      }
    }
    return FloorPlan(name: name, lot: newLot, rooms: newRooms);
  }

  FloorPlan setRoomWallLength(int roomIndex, int wallIndex, double newLengthM) {
    final Plan room = rooms[roomIndex];
    final int endIndex = (wallIndex + 1) % room.vertices.length;
    final Point2D oldEnd = room.vertices[endIndex];
    final Plan changed = room.withWallLength(wallIndex, newLengthM);
    return moveVertices(roomVerticesAt(oldEnd), changed.vertices[endIndex]);
  }

  double get builtAreaM2 => rooms.fold(0.0, (sum, room) => sum + room.areaM2);

  bool get hasRooms => rooms.isNotEmpty;

  List<Point2D> get allVertices => [
    ...?lot?.vertices,
    for (final Plan room in rooms) ...room.vertices,
  ];

  Plan? buildingBoundingBox() {
    if (rooms.isEmpty) return null;
    double minX = rooms.first.minX;
    double maxX = rooms.first.maxX;
    double minY = rooms.first.minY;
    double maxY = rooms.first.maxY;
    for (final Plan room in rooms) {
      if (room.minX < minX) minX = room.minX;
      if (room.maxX > maxX) maxX = room.maxX;
      if (room.minY < minY) minY = room.minY;
      if (room.maxY > maxY) maxY = room.maxY;
    }
    return Plan(
      name: 'Construção',
      vertices: [
        Point2D(minX, minY),
        Point2D(maxX, minY),
        Point2D(maxX, maxY),
        Point2D(minX, maxY),
      ],
    );
  }
}
