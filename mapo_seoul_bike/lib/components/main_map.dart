import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:mapo_seoul_bike/model/bike_station.dart';
import 'dart:convert';

class MainMap extends StatefulWidget {
  const MainMap({super.key});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  List<BikeStation> stations = [];  // 대여소 목록
  bool loading = true;              // 로딩 중인지

  @override
  void initState() {
    super.initState();
    loadData();  // 데이터 가져오기
  }

  // 데이터 가져오는 함수
  void loadData() async {
    try {
      // API 호출
      String apikey = '';
      String url = 'http://openapi.seoul.go.kr:8088/$apikey/json/bikeList/1/1000/';
      var response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // JSON 파싱
        var data = json.decode(response.body);
        var bikeList = data['rentBikeStatus']['row'];
        
        // 마포구 대여소만 골라내기
        List<BikeStation> mapoStations = [];
        for (var bike in bikeList) {
          String stationName = bike['stationName'] ?? '';
          
          // 마포구 키워드가 있으면 추가
          if (stationName.contains('홍대') || 
              stationName.contains('합정') || 
              stationName.contains('망원') || 
              stationName.contains('마포') ||
              stationName.contains('상암')) {
            
            mapoStations.add(BikeStation(
              name: stationName,
              lat: double.parse(bike['stationLatitude']),
              lng: double.parse(bike['stationLongitude']),
              bikes: int.parse(bike['parkingBikeTotCnt']),
              racks: int.parse(bike['rackTotCnt']),
            ));
          }
        }
        
        // 화면 업데이트
        setState(() {
          stations = mapoStations;
          loading = false;
        });
      }
    } catch (e) {
      print('오류: $e');
      setState(() {
        loading = false;
      });
    }
  }

  // 🌟 BottomSheet 보여주는 함수 (수정된 버전)
  void showStationInfo(BikeStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 자전거 수에 따라 색깔 정하기
        Color statusColor = Colors.red;
        String statusText = '이용불가';
        if (station.bikes > 5) {
          statusColor = Colors.green;
          statusText = '여유';
        } else if (station.bikes > 0) {
          statusColor = Colors.orange;
          statusText = '부족';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 제목 부분
              Row(
                children: [
                  Icon(Icons.pedal_bike, color: statusColor, size: 24), // 크기 줄임
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 16, // 크기 줄임
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20), // 크기 줄임
                  ),
                ],
              ),
              
              SizedBox(height: 16), // 간격 줄임
              
              // 🚴 자전거 정보 카드들 (크기 조정)
              Row(
                children: [
                  // 사용 가능한 자전거 수
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12), // 패딩 줄임
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10), // 둥글기 줄임
                        border: Border.all(color: statusColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${station.bikes}',
                            style: TextStyle(
                              fontSize: 20, // 크기 줄임
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text('사용 가능', style: TextStyle(fontSize: 11)), // 크기 줄임
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 10), // 간격 줄임
                  
                  // 전체 거치대 수
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12), // 패딩 줄임
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10), // 둥글기 줄임
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${station.racks}',
                            style: TextStyle(
                              fontSize: 20, // 크기 줄임
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text('전체 거치대', style: TextStyle(fontSize: 11)), // 크기 줄임
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12), // 간격 줄임
              
              // 상태 표시 (크기 조정)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10), // 패딩 줄임
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '상태: $statusText',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // 크기 줄임
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이면 로딩 표시
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    // 지도 표시
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(37.556, 126.922), // 마포구 중심
        initialZoom: 14.0,
      ),
      children: [
        // 지도 타일
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'aaa',
        ),
        // 마커들
        MarkerLayer(
          markers: stations.map((station) {
            // 자전거 수에 따라 색깔 정하기
            Color color = Colors.red;
            if (station.bikes > 5) color = Colors.green;
            else if (station.bikes > 0) color = Colors.orange;

            return Marker(
              point: LatLng(station.lat, station.lng),
              width: 40,  // 마커 크기 줄임
              height: 40,
              child: GestureDetector(
                // 🌟 마커 클릭 시 BottomSheet 열기
                onTap: () => showStationInfo(station),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pedal_bike, color: Colors.white, size: 20),
                      Text(
                        '${station.bikes}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
