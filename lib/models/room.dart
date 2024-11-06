class Room {
  final int? id;
  final String name;
  final double rent;
  final int maxOccupants;
  List<String> occupants;

  Room({
    this.id,
    required this.name,
    required this.rent,
    required this.maxOccupants,
    this.occupants = const [], // Ensure occupants is initialized to an empty list
  });

  bool get isFull => occupants.length >= maxOccupants;

  // Add the copyWith method to create a modified copy
  Room copyWith({
    int? id,
    String? name,
    double? rent,
    int? maxOccupants,
    List<String>? occupants,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      rent: rent ?? this.rent,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      occupants: occupants ?? List.from(this.occupants), // Clone the existing occupants list if not provided
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rent': rent,
      'maxOccupants': maxOccupants,
      'occupants': occupants.join(','), // Store as a comma-separated string in database
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      rent: map['rent'],
      maxOccupants: map['maxOccupants'],
      occupants: map['occupants'] == null || map['occupants'] == ''
          ? []
          : (map['occupants'] as String).split(','), // Parse occupants correctly
    );
  }
}
