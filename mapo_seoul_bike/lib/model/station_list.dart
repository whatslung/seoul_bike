class StationModel {
  final String name;
  final String line;
  final double lat;
  final double lng;

  StationModel({
    required this.name,
    required this.line,
    required this.lat,
    required this.lng,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      name: json['역사명'],
      line: json['호선'],
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
    );
  }
}
