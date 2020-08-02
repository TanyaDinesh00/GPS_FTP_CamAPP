import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
class spinnerscreen extends StatefulWidget {
  @override
  _spinnerscreenState createState() => _spinnerscreenState();
}

class _spinnerscreenState extends State<spinnerscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpinKitFadingCircle(
        itemBuilder: (BuildContext context, int index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: index.isEven ? Colors.red : Colors.green,
            ),
          );
        },
      ),
    );
  }
}
