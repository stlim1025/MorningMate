class RoomDecorationModel {
  final String wallpaperId;
  final String backgroundId; // 'none', 'forest', 'valley', 'sea', 'space'
  final List<RoomPropModel> props;

  RoomDecorationModel({
    this.wallpaperId = 'default',
    this.backgroundId = 'none',
    this.props = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'wallpaperId': wallpaperId,
      'backgroundId': backgroundId,
      'props': props.map((p) => p.toMap()).toList(),
    };
  }

  factory RoomDecorationModel.fromMap(Map<String, dynamic> map) {
    return RoomDecorationModel(
      wallpaperId: map['wallpaperId'] ?? 'default',
      backgroundId: map['backgroundId'] ?? 'none',
      props: (map['props'] as List<dynamic>?)
              ?.map((p) => RoomPropModel.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  RoomDecorationModel copyWith({
    String? wallpaperId,
    String? backgroundId,
    List<RoomPropModel>? props,
  }) {
    return RoomDecorationModel(
      wallpaperId: wallpaperId ?? this.wallpaperId,
      backgroundId: backgroundId ?? this.backgroundId,
      props: props ?? this.props,
    );
  }
}

class RoomPropModel {
  final String id;
  final String type; // 'plant', 'bear', 'lamp', 'frame', etc.
  final double x; // 0.0 ~ 1.0 (normalized relative to room width)
  final double y; // 0.0 ~ 1.0 (normalized relative to room height)

  RoomPropModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
    };
  }

  factory RoomPropModel.fromMap(Map<String, dynamic> map) {
    return RoomPropModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RoomPropModel copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
  }) {
    return RoomPropModel(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}
