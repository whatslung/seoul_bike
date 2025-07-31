class BikeStation {
  String name;        // 대여소 이름
  double lat;         // 위도 
  double lng;         // 경도
  int bikes;          // 자전거 수
  int racks;          // 거치대 수

  BikeStation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.bikes,
    required this.racks,
  });
}
