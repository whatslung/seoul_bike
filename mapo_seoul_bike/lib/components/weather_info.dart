import 'dart:convert';                    // JSON 데이터를 읽기 위해 필요
import 'package:flutter/material.dart';   // Flutter UI를 만들기 위해 필요
import 'package:http/http.dart' as http;  // 인터넷에서 데이터를 가져오기 위해 필요
import '../model/weather_model.dart';     // 위에서 만든 날씨 상자를 사용하기 위해

// 날씨 정보를 보여주는 화면을 만드는 클래스
class WeatherInfo extends StatefulWidget {
  const WeatherInfo({Key? key}) : super(key: key);

  @override
  State<WeatherInfo> createState() => _WeatherInfoState();
}

class _WeatherInfoState extends State<WeatherInfo> {
  
  final String myApiKey = '';
  
  // 마포구 좌표 (기상청에서 정해놓은 숫자)
  final String mapoPosX = '59';   // 마포구 X 좌표
  final String mapoPosY = '125';  // 마포구 Y 좌표
  
  // ============ 화면에서 사용할 변수들 ============
  
  WeatherModel? todayWeather;     // 오늘 날씨 정보를 담을 상자 (처음엔 비어있음)
  bool isDataLoading = true;      // 지금 데이터를 불러오고 있는지 확인 (처음엔 true)
  String? errorText;              // 오류가 생겼을 때 보여줄 메시지 (처음엔 null)

  // ============ 화면이 시작될 때 실행되는 함수 (수정됨) ============
  @override
  void initState() {
    super.initState();
    
    // WidgetsBinding 대신 Future.microtask 사용 (더 간단함)
    Future.microtask(() {
      getWeatherFromInternet(); // 인터넷에서 날씨 가져오는 함수 실행
    });
  }

  // ============ 인터넷에서 날씨 데이터 가져오는 함수 ============
  Future<void> getWeatherFromInternet() async {
    
    // 안전하게 로딩 상태 시작 (setState 오류 방지)
    try {
      setState(() {
        isDataLoading = true;    // 로딩 스피너 보여주기
        errorText = null;        // 이전 오류 메시지 지우기
      });
    } catch (e) {
      // 위젯이 사라졌으면 그냥 종료 (오류 방지)
      print('위젯이 이미 사라져서 로딩 상태 업데이트 불가');
      return;
    }

    try {
      // 오늘 날짜와 시간 계산하기
      DateTime nowTime = DateTime.now();           // 지금 시간
      String todayDate = makeDateString(nowTime);  // 오늘 날짜를 문자로 (예: "20250730")
      String baseTime = getBaseTimeString(nowTime); // 기상청 발표 시간 (예: "1700")
      
      print('요청할 날짜: $todayDate');
      print('요청할 시간: $baseTime');

      // 기상청에 요청할 인터넷 주소 만들기
      Uri requestUrl = Uri.https(
        'apis.data.go.kr',    // 기상청 서버 주소
        '/1360000/VilageFcstInfoService_2.0/getVilageFcst',  // 날씨 정보 요청 경로
        {
          'serviceKey': myApiKey,        // 내 API 열쇠
          'pageNo': '1',                 // 첫 번째 페이지
          'numOfRows': '300',            // 최대 300개 데이터
          'dataType': 'JSON',            // JSON 형식으로 달라고 요청
          'base_date': todayDate,        // 기준 날짜
          'base_time': baseTime,         // 기준 시간
          'nx': mapoPosX,                // 마포구 X 좌표
          'ny': mapoPosY,                // 마포구 Y 좌표
        }
      );
      
      print('요청 주소: $requestUrl');

      // 실제로 인터넷에 요청하기 (최대 20초 대기)
      var serverResponse = await http.get(requestUrl).timeout(
        Duration(seconds: 20)
      );
      
      print('서버 응답 코드: ${serverResponse.statusCode}');

      // 서버가 정상적으로 응답했는지 확인
      if (serverResponse.statusCode != 200) {
        throw Exception('서버에서 오류 응답: ${serverResponse.statusCode}');
      }

      // 혹시 오류 메시지(XML)가 왔는지 확인
      String responseText = serverResponse.body;
      if (responseText.trim().startsWith('<')) {
        throw Exception('API 키가 잘못되었거나 서비스 점검 중입니다');
      }

      // JSON 데이터 해석하기
      var jsonData = json.decode(responseText);
      
      // 응답이 성공적인지 확인
      String resultCode = jsonData['response']['header']['resultCode'];
      if (resultCode != '00') {
        String resultMessage = jsonData['response']['header']['resultMsg'];
        throw Exception('기상청 오류: $resultMessage');
      }

      // 실제 날씨 데이터 목록 가져오기
      List<dynamic> weatherDataList = jsonData['response']['body']['items']['item'];
      print('받은 데이터 개수: ${weatherDataList.length}개');

      // 데이터 목록에서 필요한 정보만 뽑아내기
      Map<String, dynamic> parsedData = findTodayWeatherFromList(weatherDataList, todayDate);
      
      // 뽑아낸 정보로 날씨 상자 만들기
      WeatherModel newWeather = WeatherModel.fromJson(parsedData);
      
      // 안전하게 화면 업데이트하기 (setState 오류 방지)
      try {
        setState(() {
          todayWeather = newWeather;   // 새로운 날씨 정보 저장
          isDataLoading = false;       // 로딩 완료
        });
        print('날씨 정보 업데이트 완료!');
      } catch (e) {
        // 위젯이 사라져서 setState 실패해도 괜찮음 (정상 상황)
        print('위젯이 사라져서 화면 업데이트 불가 (정상적인 상황)');
      }

    } catch (error) {
      // 오류가 생겼을 때 안전하게 처리
      print('오류 발생: $error');
      
      // 에러 상태 업데이트도 안전하게
      try {
        setState(() {
          errorText = '날씨 정보를 가져올 수 없습니다\n인터넷 연결을 확인해주세요';
          isDataLoading = false;
        });
      } catch (e) {
        // 위젯이 사라져서 setState 실패해도 괜찮음
        print('위젯이 사라져서 오류 상태 업데이트 불가');
      }
    }
  }

  // ============ 받은 데이터에서 오늘 날씨만 찾는 함수 ============
  Map<String, dynamic> findTodayWeatherFromList(List<dynamic> allWeatherData, String todayDate) {
    
    // 찾을 정보들을 담을 변수 (처음엔 모두 비어있음)
    String todayTemperature = '';      // 오늘 기온
    String todayHumidity = '';         // 오늘 습도  
    String todayRainChance = '';       // 오늘 강수확률
    String todaySkyCondition = '';     // 오늘 하늘상태
    String todayRainType = '';         // 오늘 비/눈 종류

    // 현재 시간에 맞는 예보 시간 계산 (예: 지금이 18시면 "1800")
    String currentHourTime = '${DateTime.now().hour.toString().padLeft(2, '0')}00';
    print('찾을 예보 시간: $currentHourTime');

    // 받은 모든 데이터를 하나씩 확인하면서 오늘 현재시간 데이터 찾기
    for (var oneWeatherData in allWeatherData) {
      
      // 오늘 날짜이고 현재 시간에 맞는 데이터인지 확인
      String dataDate = oneWeatherData['fcstDate'];     // 이 데이터의 날짜
      String dataTime = oneWeatherData['fcstTime'];     // 이 데이터의 시간
      
      if (dataDate == todayDate && dataTime == currentHourTime) {
        
        String infoType = oneWeatherData['category'];     // 데이터 종류 (온도, 습도 등)
        String infoValue = oneWeatherData['fcstValue'];   // 데이터 값
        
        // 데이터 종류에 따라 해당 변수에 저장
        if (infoType == 'TMP') {
          todayTemperature = infoValue;    // 기온 저장
        } else if (infoType == 'REH') {
          todayHumidity = infoValue;       // 습도 저장
        } else if (infoType == 'POP') {
          todayRainChance = infoValue;     // 강수확률 저장
        } else if (infoType == 'SKY') {
          todaySkyCondition = infoValue;   // 하늘상태 저장 (1:맑음, 3:구름많음, 4:흐림)
        } else if (infoType == 'PTY') {
          todayRainType = infoValue;       // 강수형태 저장 (0:없음, 1:비, 2:비/눈, 3:눈)
        }
      }
    }

    // 만약 현재 시간 데이터가 없다면 오늘의 아무 시간이나 첫 번째 데이터 사용
    if (todayTemperature.isEmpty) {
      print('현재 시간 데이터가 없어서 오늘의 다른 시간 데이터 사용');
      
      for (var oneWeatherData in allWeatherData) {
        String dataDate = oneWeatherData['fcstDate'];
        
        if (dataDate == todayDate) {
          
          String infoType = oneWeatherData['category'];
          String infoValue = oneWeatherData['fcstValue'];
          
          if (infoType == 'TMP' && todayTemperature.isEmpty) {
            todayTemperature = infoValue;
          } else if (infoType == 'REH' && todayHumidity.isEmpty) {
            todayHumidity = infoValue;
          } else if (infoType == 'POP' && todayRainChance.isEmpty) {
            todayRainChance = infoValue;
          } else if (infoType == 'SKY' && todaySkyCondition.isEmpty) {
            todaySkyCondition = infoValue;
          } else if (infoType == 'PTY' && todayRainType.isEmpty) {
            todayRainType = infoValue;
          }
        }
      }
    }

    print('찾은 오늘 날씨: 온도=$todayTemperature, 습도=$todayHumidity, 강수확률=$todayRainChance');

    // 비어있는 데이터가 있다면 기본값 넣기
    if (todayTemperature.isEmpty) todayTemperature = '20';
    if (todayHumidity.isEmpty) todayHumidity = '50';
    if (todayRainChance.isEmpty) todayRainChance = '0';
    if (todaySkyCondition.isEmpty) todaySkyCondition = '1';

    // 찾은 정보들을 Map 형태로 정리해서 반환
    return {
      'condition': makeWeatherText(todayRainType, todaySkyCondition),
      'temperature': todayTemperature,
      'humidity': todayHumidity,
      'rainProbability': todayRainChance,
    };
  }

  // ============ 보조 함수들 (간단한 계산) ============
  
  // 날짜를 "20250730" 형식으로 만드는 함수
  String makeDateString(DateTime date) {
    String year = date.year.toString();                          // 연도
    String month = date.month.toString().padLeft(2, '0');        // 월 (01, 02, ...)
    String day = date.day.toString().padLeft(2, '0');            // 일 (01, 02, ...)
    return '$year$month$day';
  }

  // 기상청 발표 시간을 계산하는 함수 (3시간마다 발표)
  String getBaseTimeString(DateTime now) {
    int currentHour = now.hour;
    
    if (currentHour >= 23) return '2300';      // 밤 11시 이후
    else if (currentHour >= 20) return '2000'; // 밤 8시 이후  
    else if (currentHour >= 17) return '1700'; // 오후 5시 이후
    else if (currentHour >= 14) return '1400'; // 오후 2시 이후
    else if (currentHour >= 11) return '1100'; // 오전 11시 이후
    else if (currentHour >= 8) return '0800';  // 오전 8시 이후
    else if (currentHour >= 5) return '0500';  // 오전 5시 이후
    else return '0200';                        // 새벽 2시 이후
  }

  // 숫자 코드를 한글 날씨로 바꾸는 함수
  String makeWeatherText(String rainType, String skyType) {
    
    // 먼저 비/눈이 오는지 확인
    if (rainType == '1') return '비';
    else if (rainType == '2') return '비/눈';
    else if (rainType == '3') return '눈';
    else if (rainType == '4') return '소나기';
    
    // 비/눈이 없으면 하늘 상태 확인
    else if (skyType == '1') return '맑음';
    else if (skyType == '3') return '구름 많음';
    else if (skyType == '4') return '흐림';
    else return '맑음';  // 기본값
  }

  // ============ 화면 그리기 (메인 Container) ============
  @override
  Widget build(BuildContext context) {
    
    // 전체 틀 만들기 (하얀색 둥근 상자)
    return Container(
      width: 400,   // 가로 크기 고정
      height: 300,  // 세로 크기 고정
      decoration: BoxDecoration(
        color: Colors.white,                         // 배경색: 하얀색
        borderRadius: BorderRadius.circular(22),     // 모서리 둥글게
        boxShadow: [                                 // 그림자 효과
          BoxShadow(
            color: Colors.black12, 
            blurRadius: 10, 
            offset: Offset(2, 8)
          )
        ],
      ),
      child: SingleChildScrollView(  // 오버플로우 방지용 스크롤 추가
        padding: EdgeInsets.all(28),  // 안쪽 여백
        child: showWeatherContent(),  // 실제 내용 보여주기
      ),
    );
  }

  // ============ 상황별 화면 내용 함수 (원래 디자인 유지) ============
  Widget showWeatherContent() {
    
    // 경우 1: 아직 데이터를 불러오는 중
    if (isDataLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,  // 오버플로우 방지
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),  // 돌아가는 로딩 아이콘
          SizedBox(height: 16),
          Text('서울 마포구 날씨 정보를 가져오는 중...'),
        ],
      );
    }

    // 경우 2: 오류가 발생했을 때
    if (errorText != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,  // 오버플로우 방지
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 8),
          Text(
            errorText!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              getWeatherFromInternet(); // 다시 시도 버튼
            },
            child: Text('다시 시도'),
          ),
        ],
      );
    }

    // 경우 3: 데이터가 없을 때
    if (todayWeather == null) {
      return Center(
        child: Text('날씨 데이터가 없습니다'),
      );
    }

    // 경우 4: 정상적으로 날씨 정보 보여주기 (원래 디자인: 왼쪽 아이콘 + 오른쪽 정보)
    return IntrinsicHeight(  // 높이 자동 조절 (오버플로우 해결)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,  // 세로로 꽉 채우기
        children: [
          
          // 날씨 아이콘
          Padding(
            padding: EdgeInsets.only(right: 40),  // 오른쪽에 40px 간격
            child: getWeatherIcon(todayWeather!.statusText),
          ),
          
          // 날씨 정보 텍스트들
          Flexible(  // Expanded 대신 Flexible 사용 (오버플로우 방지)
            child: Column(
              mainAxisSize: MainAxisSize.min,  // 오버플로우 방지
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                //  날씨 상태 (맑음, 흐림 등)
                Row(
                  children: [
                    SizedBox(width: 12),
                    Flexible(  // 텍스트 오버플로우 방지
                      child: Text(
                        todayWeather!.statusText,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,  // 길면 ... 처리
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),  // 고정 간격 (Spacer 대신)
                
                // 중앙: 온도 (큰 글씨)
                Text(
                  '${todayWeather!.temperature}°C',
                  style: TextStyle(
                    fontSize: 60, 
                    fontWeight: FontWeight.w700, 
                    color: Colors.black87
                  ),
                ),
                
                SizedBox(height: 10),  // 간격
                
                // 하단: 습도와 강수확률 (원래 레이아웃 유지)
                Row(
                  children: [
                    
                    // 습도 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('습도', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('${todayWeather!.humidity}%', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                    
                    SizedBox(width: 40), // 간격
                    
                    // 강수확률 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('강수확률', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('${todayWeather!.rainProbability}%', style: TextStyle(fontSize: 22)),
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

  // ============ 날씨 상태에 맞는 아이콘을 보여주는 함수 ============
  Widget getWeatherIcon(String weatherCondition) {
    
    // 날씨 상태별로 다른 아이콘과 색상 반환
    if (weatherCondition == '맑음') {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 100);  // 태양 아이콘
      
    } else if (weatherCondition == '구름 많음') {
      return Icon(Icons.wb_cloudy, color: Colors.grey[600], size: 100);  // 구름 아이콘
      
    } else if (weatherCondition == '흐림') {
      return Icon(Icons.cloud, color: Colors.grey[700], size: 100);  // 흐린 구름 아이콘
      
    } else if (weatherCondition == '비' || weatherCondition == '소나기') {
      return Icon(Icons.grain, color: Colors.blue, size: 100);  // 비 아이콘
      
    } else if (weatherCondition == '눈' || weatherCondition == '비/눈') {
      return Icon(Icons.ac_unit, color: Colors.lightBlue, size: 100);  // 눈 아이콘
      
    } else {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 100);  // 기본값: 맑음
    }
  }
}
