// 이 파일은 날씨 정보를 담는 작은 상자 같은 역할을 합니다
class WeatherModel {
  // 날씨 상태 (맑음, 흐림 등)
  final String condition;
  
  // 온도 (예: "25")
  final String temperature;
  
  // 습도 (예: "60")
  final String humidity;
  
  // 비올 확률 (예: "30")
  final String rainProbability;

  // 이 상자를 만들 때 반드시 필요한 정보들
  WeatherModel({
    required this.condition,      // 날씨상태 필수
    required this.temperature,    // 온도 필수
    required this.humidity,       // 습도 필수
    required this.rainProbability, // 강수확률 필수
  });

  // 숫자로 된 날씨 코드를 사람이 읽기 좋은 한글로 바꿔주는 기능
  String get statusText {
    if (condition == '1') {
      return '맑음';
    } else if (condition == '3') {
      return '구름 많음';
    } else if (condition == '4') {
      return '흐림';
    } else {
      return condition; // 이미 한글이면 그대로 사용
    }
  }

  // 인터넷에서 받은 데이터를 이 상자에 넣는 기능
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      condition: json['condition'] ?? '알수없음',
      temperature: json['temperature'] ?? '0',
      humidity: json['humidity'] ?? '0',
      rainProbability: json['rainProbability'] ?? '0',
    );
  }
}
