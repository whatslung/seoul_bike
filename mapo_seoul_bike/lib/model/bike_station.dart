class BikeStation {
  final String name;
  final double longitude;
  final double latitude;

  BikeStation(
    {
    required this.name,
    required this.longitude,
    required this.latitude,
    }
  );


//임의 데이터
final List<BikeStation> dummyStations = 
    [
      BikeStation(name: "망원역 1번출구", longitude: 126.910, latitude: 37.555),
      BikeStation(name: "합정역 2번출구", longitude: 126.913, latitude: 37.549),
      BikeStation(name: "홍대입구역 3번출구", longitude: 126.922, latitude: 37.557),
    ];

}
