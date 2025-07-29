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
        Text('Seoul Bike Logo'),
      ],
    );
  }//build

  //---functions---


}//class
