import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MainMap extends StatefulWidget {
  const MainMap({super.key});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  late MapController mapController;
  List<dynamic> location = []; // location 빈 배열로 시작

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    location = [
      ['혜화문', 37.5878892, 127.0037098],
      ['흥인지문', 37.5711907, 127.009506],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: location.isNotEmpty
            ? latlong.LatLng(location[0][1], location[0][2])
            : latlong.LatLng(37.5665, 126.9780), // 서울시청 기준 
        initialZoom: 17.0,
        minZoom: 15.0,    // 너무 많이 줌 아웃 방지
        maxZoom: 30.0,   // 줌 범위 제한
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'aaa',
        ),
        MarkerLayer(
          markers: location.isNotEmpty
              ? location
                    .map(
                      (item) =>
                          makeMarker(
                            item[0], 
                            item[1], 
                            item[2], 
                            Colors.red
                          ),
                    )
                    .toList()
              : [],
        ),
      ],
    );
  }

  Marker makeMarker(String name, double lat, double long, Color mColor) {
    return Marker(
      width: 80,
      height: 80,
      point: latlong.LatLng(lat, long),
      child: Column(
        children: [
          SizedBox(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.location_on, size: 50, color: mColor),
        ],
      ),
    );
  }
}
