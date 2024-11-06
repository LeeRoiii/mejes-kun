class Tenant {
  int? id;
  String name;
  String email;
  String mobile;
  String sex;
  int? roomId; // Make roomId mutable
  int monthsPaid;

  Tenant({
    this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.sex,
    this.roomId,
    this.monthsPaid = 0,
  });

  Tenant copyWith({
    int? id,
    String? name,
    String? email,
    String? mobile,
    String? sex,
    int? roomId,
    int? monthsPaid,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      sex: sex ?? this.sex,
      roomId: roomId ?? this.roomId,
      monthsPaid: monthsPaid ?? this.monthsPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'sex': sex,
      'roomId': roomId,
      'monthsPaid': monthsPaid,
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      mobile: map['mobile'],
      sex: map['sex'],
      roomId: map['roomId'],
      monthsPaid: map['monthsPaid'] ?? 0,
    );
  }
}
