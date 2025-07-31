import 'package:flutter/material.dart';

class Appbartitle extends StatefulWidget {
  const Appbartitle({super.key});

  @override
  State<Appbartitle> createState() => _AppbartitleState();
}

class _AppbartitleState extends State<Appbartitle> {
  late TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('images/1.jpg',width: 40,height: 25,),
        SizedBox(width: 10,),
        Text('Seoul Bike in mapo',
        style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }//build

  //---functions---


}//class
