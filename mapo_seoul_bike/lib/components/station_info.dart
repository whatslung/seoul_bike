import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapo_seoul_bike/model/bike_station.dart';

class StationInfo extends StatefulWidget {
  final List<BikeStation> stations;

  const StationInfo({super.key, required this.stations});

  @override
  State<StationInfo> createState() => _StationInfoState();
}

class _StationInfoState extends State<StationInfo> {
  final LatLng center = LatLng(37.556, 126.922);
  final Distance distance = Distance();
  late List<BikeStation> nearest5;

  @override
  void initState() {
    super.initState();
    nearest5 = widget.stations.toList()
      ..sort((a, b) =>
          distance(center, LatLng(a.lat, a.lng)).compareTo(
            distance(center, LatLng(b.lat, b.lng)),
          ));
    nearest5 = nearest5.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nearest5.map((station) {
          Color statusColor;
          String statusText;

          if (station.bikes > 5) {
            statusColor = Colors.green;
            statusText = '여유';
          } else if (station.bikes > 0) {
            statusColor = Colors.orange;
            statusText = '부족';
          } else {
            statusColor = Colors.red;
            statusText = '이용불가';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    station.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 30,),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
