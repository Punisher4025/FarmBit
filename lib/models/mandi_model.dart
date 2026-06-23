class Mandi {
  final String id;
  final String name;
  final String state;
  final String district;
  final String volumeStatus; // 'High', 'Medium', 'Low'

  Mandi({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    required this.volumeStatus,
  });

  factory Mandi.fromJson(Map<String, dynamic> json) {
    return Mandi(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      volumeStatus: json['volumeStatus'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'district': district,
      'volumeStatus': volumeStatus,
    };
  }
}
