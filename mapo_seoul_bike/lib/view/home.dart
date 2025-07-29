import 'package:flutter/material.dart';
import 'package:mapo_seoul_bike/components/appbar_title.dart';
import 'package:mapo_seoul_bike/components/main_map.dart';
import 'package:mapo_seoul_bike/components/station_info.dart';
import 'package:mapo_seoul_bike/components/weather_info.dart';
import 'package:responsive_framework/responsive_framework.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // 원하는 높이 지정 (ex: 80)
        child: AppBar(
          title: Appbartitle(),
          actions: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 300,
                  height: 45,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '대여소 이름을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                //
              },
              icon: Icon(Icons.search_rounded),
            ),
          ], 
          backgroundColor: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Color(0xff3D5567),
            
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                color: Color(0xff30E291)
              ),
              height: MediaQuery.of(context).size.height * 0.5,
              
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: ListView(
              children: [
                ResponsiveRowColumn(
                  rowMainAxisAlignment: MainAxisAlignment.center,
                  rowPadding: EdgeInsets.all(30),
                  columnPadding: EdgeInsets.all(30),
                  layout: ResponsiveBreakpoints.of(context).isDesktop
                      ? ResponsiveRowColumnType.ROW
                      : ResponsiveRowColumnType.COLUMN,
                  children: [
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child:
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: WeatherInfo(),
                          ), //model에서 가져올 정보있으면 가져오기 예 (child: CourseTile(course: courses[0]))
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1, 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: StationInfo(),
                      )
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 400,
                    child: MainMap())),
              ],
            ),
          ),
          SizedBox(
            height: 50,
          )
        ],
      ),
    );
  } // build

  //---functions---
} // class

//반응형 필요시 사용
// ResponsiveVisibility(
//     hiddenConditions: [
//       Condition.largerThan(value: true, name: MOBILE) //mobile보다 크면 보여준다.
//     ],
//     child: MenuTextButton(text: 'Course'),
//   ),
