class WeatherData {
  final String date;
  final String time;
  final String tTime;
  final String temp;
  final String rain;
  final String rainratio;

  WeatherData({
    required this.date,
    required this.time,
    required this.tTime,
    required this.temp,
    required this.rain,
    required this.rainratio,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      date: json['date'],
      time: json['time'],
      tTime: json['시각']?.toString().replaceAll('시', '') ?? "",
      temp: json['기온'],
      rain: json['강수량'],
      rainratio: json['습도'],
    );
  }
}
