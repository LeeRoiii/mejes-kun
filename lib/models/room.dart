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
