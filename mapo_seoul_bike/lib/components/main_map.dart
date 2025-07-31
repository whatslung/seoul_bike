import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:mapo_seoul_bike/model/bike_station.dart';
import 'dart:convert';
import 'package:mapo_seoul_bike/services/api_service.dart';

class MainMap extends StatefulWidget {
  final Function(List<BikeStation>) onStationsLoaded;

  const MainMap({super.key, required this.onStationsLoaded});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  List<BikeStation> stations = []; // 대여소 목록
  bool loading = true; // 로딩 중인지

  // ✅ dropdown용 변수 추가
  int selectedHour = 12; // 기본 선택값

  // ✅ 불쾌지수 계산
  double calculateDiscomfortIndex(double temp, double humid) {
    return 0.81 * temp + 0.01 * humid * (0.99 * temp - 14.3) + 46.3;
  }

  double? predictionResult; // 예측값

  @override
  void initState() {
    super.initState();
    loadData(); // 데이터 가져오기
    fetchWeatherData();
  }

  // 데이터 가져오는 함수 (기존과 동일)
  void loadData() async {
    try {
      // API 호출
      String apikey = '73526e626873656f3735645975554a';
      String url =
          'http://openapi.seoul.go.kr:8088/$apikey/json/bikeList/1/1000/';
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // JSON 파싱
        var data = json.decode(response.body);
        var bikeList = data['rentBikeStatus']['row'];

        // 마포구 대여소만 골라내기
        List<String> mapoStationIds = [
          'ST-992',
          'ST-991',
          'ST-990',
          'ST-989',
          'ST-982',
          'ST-968',
          'ST-96',
          'ST-95',
          'ST-94',
          'ST-92',
          'ST-91',
          'ST-90',
          'ST-9',
          'ST-89',
          'ST-88',
          'ST-87',
          'ST-86',
          'ST-85',
          'ST-84',
          'ST-83',
          'ST-82',
          'ST-81',
          'ST-80',
          'ST-8',
          'ST-79',
          'ST-78',
          'ST-77',
          'ST-76',
          'ST-74',
          'ST-7',
          'ST-6',
          'ST-5',
          'ST-443',
          'ST-4',
          'ST-38',
          'ST-344',
          'ST-343',
          'ST-342',
          'ST-341',
          'ST-340',
          'ST-339',
          'ST-3380',
          'ST-3355',
          'ST-3272',
          'ST-3271',
          'ST-3244',
          'ST-3213',
          'ST-32',
          'ST-3130',
          'ST-31',
          'ST-3022',
          'ST-3021',
          'ST-3020',
          'ST-3019',
          'ST-3018',
          'ST-3017',
          'ST-3016',
          'ST-3008',
          'ST-3',
          'ST-2983',
          'ST-2982',
          'ST-2981',
          'ST-2980',
          'ST-2979',
          'ST-2978',
          'ST-2977',
          'ST-2976',
          'ST-2975',
          'ST-2974',
          'ST-2905',
          'ST-29',
          'ST-2874',
          'ST-28',
          'ST-27',
          'ST-26',
          'ST-2537',
          'ST-2536',
          'ST-2535',
          'ST-2534',
          'ST-2533',
          'ST-2532',
          'ST-2531',
          'ST-2530',
          'ST-2529',
          'ST-2528',
          'ST-24',
          'ST-23',
          'ST-22',
          'ST-2170',
          'ST-2169',
          'ST-2168',
          'ST-2167',
          'ST-2166',
          'ST-2165',
          'ST-2164',
          'ST-2163',
          'ST-2162',
          'ST-2161',
          'ST-2160',
          'ST-2159',
          'ST-2158',
          'ST-2157',
          'ST-2156',
          'ST-2155',
          'ST-2154',
          'ST-2153',
          'ST-2152',
          'ST-2151',
          'ST-2150',
          'ST-2149',
          'ST-2148',
          'ST-2147',
          'ST-2146',
          'ST-214',
          'ST-213',
          'ST-212',
          'ST-211',
          'ST-210',
          'ST-21',
          'ST-209',
          'ST-208',
          'ST-207',
          'ST-206',
          'ST-205',
          'ST-204',
          'ST-203',
          'ST-202',
          'ST-201',
          'ST-200',
          'ST-20',
          'ST-2',
          'ST-19',
          'ST-18',
          'ST-1754',
          'ST-1693',
          'ST-1692',
          'ST-1691',
          'ST-1675',
          'ST-16',
          'ST-15',
          'ST-1494',
          'ST-1492',
          'ST-1397',
          'ST-110',
          'ST-11',
          'ST-10',
        ];

        List<BikeStation> mapoStations = [];

        for (var bike in bikeList) {
          String stationId = bike['stationId'] ?? '';

          // stationId가 목록에 포함되면 추가
          if (mapoStationIds.contains(stationId)) {
            mapoStations.add(
              BikeStation(
                name: bike['stationName'],
                lat: double.parse(bike['stationLatitude']),
                lng: double.parse(bike['stationLongitude']),
                bikes: int.parse(bike['parkingBikeTotCnt']),
                racks: int.parse(bike['rackTotCnt']),
              ),
            );
          }
        }

        // 화면 업데이트
        setState(() {
          stations = mapoStations;
          loading = false;
        });
        print("📡 mapoStations loaded: ${mapoStations.length}");
        widget.onStationsLoaded(mapoStations);
      }
    } catch (e) {
      print('오류: $e');
      setState(() {
        loading = false;
      });
    }
  }

  // ✅ BottomSheet에 dropdown UI 추가
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
              // 제목 부분
              Row(
                children: [
                  Icon(Icons.pedal_bike, color: statusColor, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 20),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // ✅ dropdown UI 추가
              Row(
                children: [
                  Text(
                    '이용예측 시간 선택',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  DropdownButton<int>(
                    value: selectedHour,
                    items: [
                      for (int i = 0; i <= 23; i++)
                        DropdownMenuItem(value: i, child: Text('${i}시')),
                    ],
                    onChanged: (hour) {
                      if (hour == null) return;
                      setState(() => selectedHour = hour);
                      Navigator.pop(context);
                      showStationInfo(station); // 즉시 업데이트
                    },
                  ),
                  // Icon(Icons.wb_sunny, color: Colors.orange, size: 30)
                  ElevatedButton(
                    
                    onPressed: () async {
                      final weatherNow = getWeatherByHour(15);
                      // await getWeatherByHour(selectedHour);
                      final temp = double.parse(weatherNow?['기온']);
                      final humid = double.parse(weatherNow?['습도']);
                      // double temp = double.tryParse(weather[0]['기온'].toString()) ?? 0;
                      // double humid = double.tryParse(weather[0]['습도'].toString()) ?? 0;
                      final discomfort = calculateDiscomfortIndex(temp, humid);

                      final prediction = await sendPrediction(
                        hour: selectedHour,
                        rackCount: station.racks,
                        discomfort: discomfort,
                      );

                      if (prediction != null) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text('예측 결과',style: TextStyle(color: Colors.black)),
                              content: Text(
                                '예상 사용 가능 수: ${prediction.toStringAsFixed(0)}대',
                                style: TextStyle(fontSize: 16,color: Colors.black),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('확인',style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('예측 실패'),
                              content: Text('예측 중 오류가 발생했어요. 다시 시도해주세요.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: 
                    Colors.white),
                    child: Text("이 시간대 예측하기", style: TextStyle(color: Colors.black),),
                  ),
                ],
              ),

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),

              // 자전거 정보 카드들 (기존과 동일)
              Row(
                children: [
                  // 사용 가능한 자전거 수
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor),
                      ),
                      child: Column(
                        children: [
                          // Text(
                          //   '${station.bikes}',
                          //   style: TextStyle(
                          //     fontSize: 20,
                          //     fontWeight: FontWeight.bold,
                          //     color: statusColor,
                          //   ),
                          // ),
                          Text(
                            '${predictionResult?.toStringAsFixed(0) ?? station.bikes}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text('사용 가능', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 10),
                  // 전체 거치대 수
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${station.racks}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text('전체 거치대', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              // 상태 표시
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '상태: $statusText',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
            if (station.bikes > 5)
              color = Colors.green;
            else if (station.bikes > 0)
              color = Colors.orange;

            return Marker(
              point: LatLng(station.lat, station.lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                // 마커 클릭 시 BottomSheet 열기
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
