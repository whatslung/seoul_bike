import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mapo_seoul_bike/model/bike_station.dart';
import 'package:mapo_seoul_bike/model/jsonweather.dart';
import 'package:mapo_seoul_bike/model/station_list.dart';

class MainMap extends StatefulWidget {
  const MainMap({super.key});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  List<BikeStation> stations = [];
  List<WeatherData> weatherList = [];
  List<StationModel> subwayList = [];
  bool loading = true;
  late PopupController popupController;
  int selectedHour = 12;
  int predictedBikes = 0;
  BikeStation? selectedStation;

  @override
  void initState() {
    super.initState();
    popupController = PopupController();
    loadData();
    fetchWeather();
    loadSubway();
  }

  Future<void> fetchWeather() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/weather');
      final response = await http.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('API status: ${jsonResponse['status']}');

        if (jsonResponse['status'] == 'success') {
          List<dynamic> data = jsonResponse['data'];
          setState(() {
            weatherList = data.map((e) => WeatherData.fromJson(e)).toList();
          });
        } else {
          print('날씨 API status 실패: ${jsonResponse['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('날씨 정보 불러오기 오류: $e');
    }
  }

  WeatherData? getSelectedWeather() {
    String todayDate = weatherList.isNotEmpty
        ? weatherList[0].date
        : DateTime.now().toIso8601String().substring(0, 10);
    print('todayDate used for matching: [$todayDate]');
    print('selectedHour: $selectedHour');

    // 1. 날짜가 오늘 날짜인 데이터 필터
    var todayData = weatherList.where((w) => w.date == todayDate).toList();

    if (todayData.isEmpty) {
      print('No weather data for today');
      return null;
    }

    // 2. 선택시간과 가장 가까운 시각 찾기
    int? closestHour;
    WeatherData? closestWeather;
    int minDiff = 24; // 최대 24시간 차이

    for (var w in todayData) {
      int? hour = int.tryParse(w.tTime.trim());
      if (hour == null) continue;
      int diff = (hour - selectedHour).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestHour = hour;
        closestWeather = w;
      }
    }

    if (closestWeather != null) {
      print(
        'Closest weather data found at hour $closestHour: temp=${closestWeather.temp}',
      );
      return closestWeather;
    } else {
      print(
        'No matching weather data found for $todayDate and hour $selectedHour',
      );
      return null;
    }
  }

  Future<void> fetchPrediction(BikeStation station, WeatherData weather) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/sang_predict');
      DateTime now = DateTime.now();
      DateTime targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedHour,
      );

      final body = jsonEncode({
        '날짜': targetDateTime.toIso8601String(),
        '기온': double.tryParse(weather.temp) ?? 0.0,
        '강수량': double.tryParse(weather.rain) ?? 0.0,
        '위도': station.lat,
        '경도': station.lng,
      });

      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictedBikes = data['predicted_자전거'] ?? 0;
        });
      } else {
        print('예측 API 실패 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('예측 API 호출 오류: $e');
    }
  }

  Future<void> loadSubway() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/stations"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          subwayList = jsonList
              .map((json) => StationModel.fromJson(json))
              .toList();
        });
      } else {
        print('지하철 API 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('지하철 API 오류: $e');
    }
  }

  Future<void> loadData() async {
    try {
      String apikey = '574d745442726b643732445a696869';
      String url =
          'http://openapi.seoul.go.kr:8088/$apikey/json/bikeList/1/1000/';
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var bikeList = data['rentBikeStatus']['row'];
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
        setState(() {
          stations = mapoStations;
          loading = false;
        });
      }
    } catch (e) {
      print('대여소 로드 오류: $e');
      setState(() {
        loading = false;
      });
    }
  }

  void showStationInfo(BikeStation station) async {
    selectedStation = station;
    WeatherData? weather = getSelectedWeather();
    if (weather != null) {
      await fetchPrediction(station, weather);
    } else {
      setState(() {
        predictedBikes = 0;
      });
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        WeatherData? currentWeather = getSelectedWeather();

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Row(
                  children: [
                    Text(
                      '이용예측 시간 선택',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 12),
                    DropdownButton<int>(
                      value: selectedHour,
                      items: List.generate(24, (i) => i + 1)
                          .map(
                            (hour) => DropdownMenuItem(
                              value: hour,
                              child: Text('$hour 시'),
                            ),
                          )
                          .toList(),
                      onChanged: (hour) {
                        if (hour == null) return;
                        setState(() {
                          selectedHour = hour;
                          predictedBikes = 0;
                        });
                        Navigator.pop(context);
                        if (selectedStation != null) {
                          showStationInfo(selectedStation!);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),

                // 날씨 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('기온: ${currentWeather?.temp ?? '-'} °C'),
                    Text('강수량: ${currentWeather?.rain ?? '-'} mm'),
                    Text('습도: ${currentWeather?.rainratio ?? '-'} %'),
                  ],
                ),

                SizedBox(height: 16),

                // 자전거 상태 카드
                Row(
                  children: [
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
                            Text(
                              '${station.bikes}',
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

                SizedBox(height: 16),

                Text(
                  '예측 자전거 수: $predictedBikes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(37.556, 126.922),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'mapo_seoul_bike',
        ),
        MarkerLayer(
          markers: stations.map((station) {
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
                onTap: () {
                  showStationInfo(station);
                },
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
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            popupController: popupController,
            markers: subwayList.asMap().entries.map((entry) {
              final index = entry.key;
              final station = entry.value;
              final point = LatLng(station.lat, station.lng);
              late final Marker marker;
              marker = Marker(
                key: ValueKey('station-${station.name}|${station.line}|$index'),
                point: point,
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    popupController.togglePopup(marker);
                  },
                  child: Icon(Icons.subway, color: Colors.red, size: 18),
                ),
              );
              return marker;
            }).toList(),
            popupDisplayOptions: PopupDisplayOptions(
              builder: (context, marker) {
                final key = marker.key as ValueKey<String>?;
                final keyValue = key?.value ?? '';
                String label = '정보 없음';
                if (keyValue.startsWith('station-')) {
                  final parts = keyValue
                      .replaceFirst('station-', '')
                      .split('|');
                  if (parts.length >= 2) {
                    label = '역: ${parts[0]}\n호선: ${parts[1]}';
                  }
                }
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(label, style: TextStyle(fontSize: 14)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
