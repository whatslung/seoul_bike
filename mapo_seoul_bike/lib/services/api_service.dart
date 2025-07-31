import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double?> sendPrediction({
  required int hour,
  required int rackCount,
  required double discomfort,
}) async {
  final url = Uri.parse("http://127.0.0.1:8000/predict"); // 실제 서버 주소로 변경

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "hour": hour,
      "rack_count": rackCount,
      "discomfort": discomfort,
    }),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    return result['prediction'] * 1.0;
  } else {
    print("API 오류: ${response.statusCode}");
    return null;
  }
}


final String baseUrl = 'http://127.0.0.1:8000';

List<dynamic> weather = [];

/// 날씨 데이터를 FastAPI로부터 불러오는 함수
Future<void> fetchWeatherData() async {
  try {
    weather.clear();

    final res = await http.get(Uri.parse("$baseUrl/weather"));

    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));

      if (data['status'] == 'success') {
        weather = data['data'];
        print("✅ 날씨 데이터 ${weather.length}개 불러옴");
      } else {
        print("❌ 서버 오류: ${data['message']}");
      }
    } else {
      print("❌ HTTP 오류: ${res.statusCode}");
    }
  } catch (e) {
    print("❌ 예외 발생: $e");
  }
}

/// 특정 시간(0~23)에 가장 가까운 날씨 데이터를 반환하는 함수
Map<String, dynamic>? getWeatherByHour(int targetHour) {
  if (weather.isEmpty || targetHour < 0 || targetHour > 23) return null;

  Map<String, dynamic>? closest;
  int? minDiff;

  for (final item in weather) {
    final String timeStr = item['시각'] ?? item['time'] ?? '';
    final int? itemHour = int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), ''));

    if (itemHour == null) continue;

    final diff = (itemHour - targetHour).abs();

    if (minDiff == null || diff < minDiff) {
      minDiff = diff;
      closest = item;
    }
  }

  return closest;
}