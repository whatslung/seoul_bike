import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../model/weather_model.dart';

class WeatherInfo extends StatefulWidget {
  const WeatherInfo({Key? key}) : super(key: key);

  @override
  State<WeatherInfo> createState() => _WeatherInfoState();
}

class _WeatherInfoState extends State<WeatherInfo> {
  final String apiKey = 'nDbOi0vFeQlu1W5LTSb+tR7aSqmYL0e+aJJ9cfKOavdd5HUh8C1JYeJPS6q2QDgGXRyvZrEDYG8RAa+jNRAogw==';  // API 키 입력
  final String mapoPosX = '59';   // 마포구 X 좌표
  final String mapoPosY = '125';  // 마포구 Y 좌표
  
  WeatherModel? weather;  // 날씨 정보
  bool loading = true;    // 로딩 상태
  String? error;          // 오류 메시지

  @override
  void initState() {
    super.initState();
    // 가장 간단한 방법: 바로 호출
    loadWeatherData();
  }

  // 날씨 데이터 가져오기
  Future<void> loadWeatherData() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });
    } catch (e) {
      return;
    }

    try {
      DateTime now = DateTime.now();
      String date = getDateString(now);
      String baseTime = getBaseTime(now);
      
      // API 요청 URL 생성
      Uri url = Uri.https(
        'apis.data.go.kr',
        '/1360000/VilageFcstInfoService_2.0/getVilageFcst',
        {
          'serviceKey': apiKey,
          'pageNo': '1',
          'numOfRows': '300',
          'dataType': 'JSON',
          'base_date': date,
          'base_time': baseTime,
          'nx': mapoPosX,
          'ny': mapoPosY,
        }
      );
      
      // API 호출
      var response = await http.get(url).timeout(Duration(seconds: 20));
      
      if (response.statusCode != 200) {
        throw Exception('서버 오류: ${response.statusCode}');
      }

      String responseBody = response.body;
      if (responseBody.trim().startsWith('<')) {
        throw Exception('API 키 오류 또는 서비스 점검');
      }

      // JSON 파싱
      var data = json.decode(responseBody);
      String resultCode = data['response']['header']['resultCode'];
      
      if (resultCode != '00') {
        String resultMsg = data['response']['header']['resultMsg'];
        throw Exception('기상청 오류: $resultMsg');
      }

      List<dynamic> items = data['response']['body']['items']['item'];
      Map<String, dynamic> parsedData = parseWeatherData(items, date);
      WeatherModel newWeather = WeatherModel.fromJson(parsedData);
      
      // 화면 업데이트
      try {
        setState(() {
          weather = newWeather;
          loading = false;
        });
      } catch (e) {
        // 위젯이 사라진 경우 무시
      }

    } catch (e) {
      try {
        setState(() {
          error = '날씨 정보를 가져올 수 없습니다\n인터넷 연결을 확인해주세요';
          loading = false;
        });
      } catch (e) {
        // 위젯이 사라진 경우 무시
      }
    }
  }

  // 날씨 데이터 파싱
  Map<String, dynamic> parseWeatherData(List<dynamic> items, String date) {
    String temperature = '';
    String humidity = '';
    String rainChance = '';
    String skyCondition = '';
    String rainType = '';

    String currentTime = '${DateTime.now().hour.toString().padLeft(2, '0')}00';

    // 현재 시간 데이터 찾기
    for (var item in items) {
      String itemDate = item['fcstDate'];
      String itemTime = item['fcstTime'];
      
      if (itemDate == date && itemTime == currentTime) {
        String category = item['category'];
        String value = item['fcstValue'];
        
        switch (category) {
          case 'TMP': temperature = value; break;
          case 'REH': humidity = value; break;
          case 'POP': rainChance = value; break;
          case 'SKY': skyCondition = value; break;
          case 'PTY': rainType = value; break;
        }
      }
    }

    // 현재 시간 데이터가 없으면 오늘 다른 시간 데이터 사용
    if (temperature.isEmpty) {
      for (var item in items) {
        String itemDate = item['fcstDate'];
        
        if (itemDate == date) {
          String category = item['category'];
          String value = item['fcstValue'];
          
          if (category == 'TMP' && temperature.isEmpty) temperature = value;
          else if (category == 'REH' && humidity.isEmpty) humidity = value;
          else if (category == 'POP' && rainChance.isEmpty) rainChance = value;
          else if (category == 'SKY' && skyCondition.isEmpty) skyCondition = value;
          else if (category == 'PTY' && rainType.isEmpty) rainType = value;
        }
      }
    }

    // 기본값 설정
    if (temperature.isEmpty) temperature = '20';
    if (humidity.isEmpty) humidity = '50';
    if (rainChance.isEmpty) rainChance = '0';
    if (skyCondition.isEmpty) skyCondition = '1';

    return {
      'condition': getWeatherCondition(rainType, skyCondition),
      'temperature': temperature,
      'humidity': humidity,
      'rainProbability': rainChance,
    };
  }

  // 날짜 문자열 생성
  String getDateString(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  // 기상청 발표 시간 계산
  String getBaseTime(DateTime now) {
    int hour = now.hour;
    
    if (hour >= 23) return '2300';
    else if (hour >= 20) return '2000';
    else if (hour >= 17) return '1700';
    else if (hour >= 14) return '1400';
    else if (hour >= 11) return '1100';
    else if (hour >= 8) return '0800';
    else if (hour >= 5) return '0500';
    else return '0200';
  }

  // 날씨 상태 문자열 생성
  String getWeatherCondition(String rainType, String skyType) {
    if (rainType == '1') return '비';
    else if (rainType == '2') return '비/눈';
    else if (rainType == '3') return '눈';
    else if (rainType == '4') return '소나기';
    else if (skyType == '1') return '맑음';
    else if (skyType == '3') return '구름 많음';
    else if (skyType == '4') return '흐림';
    else return '맑음';
  }

  // 날씨 아이콘 반환
  Widget getWeatherIcon(String condition) {
    if (condition == '맑음') {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 100);
    } else if (condition == '구름 많음') {
      return Icon(Icons.wb_cloudy, color: Colors.grey[600], size: 100);
    } else if (condition == '흐림') {
      return Icon(Icons.cloud, color: Colors.grey[700], size: 100);
    } else if (condition == '비' || condition == '소나기') {
      return Icon(Icons.grain, color: Colors.blue, size: 100);
    } else if (condition == '눈' || condition == '비/눈') {
      return Icon(Icons.ac_unit, color: Colors.lightBlue, size: 100);
    } else {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 450,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 8),
          )
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(28),
        child: buildWeatherContent(),
      ),
    );
  }

  // 날씨 내용 위젯 생성
  Widget buildWeatherContent() {
    // 로딩 중
    if (loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('서울 마포구 날씨 정보를 가져오는 중...'),
        ],
      );
    }

    // 오류 발생
    if (error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => loadWeatherData(),
            child: Text('다시 시도'),
          ),
        ],
      );
    }

    // 데이터 없음
    if (weather == null) {
      return Center(child: Text('날씨 데이터가 없습니다'));
    }

    // 정상 날씨 정보 표시
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 날씨 아이콘
          Padding(
            padding: EdgeInsets.only(right: 40, left: 40),
            child: getWeatherIcon(weather!.statusText),
          ),
          
          // 날씨 정보
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날씨 상태
                Row(
                  children: [
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        weather!.statusText,
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // 온도
                Text(
                  '${weather!.temperature}°C',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 10),
                
                // 습도와 강수확률
                Row(
                  children: [
                    // 습도
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('습도', style: TextStyle(
                          fontSize: 14, 
                          color: Colors.black54,
                        )),
                        Text('${weather!.humidity}%', style: TextStyle(
                          fontSize: 22,
                        )),
                      ],
                    ),
                    
                    SizedBox(width: 40),
                    
                    // 강수확률
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('강수확률', style: TextStyle(
                          fontSize: 14, 
                          color: Colors.black54,
                        )),
                        Text('${weather!.rainProbability}%', style: TextStyle(
                          fontSize: 22,
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
