import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'screen2.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

//class LoadingScreen extends StatefulWidget {
//  LoadingScreen({this.locationData});
//  final locationData;
//  @override
//  _LoadingScreenState createState() => _LoadingScreenState();
//}
//
//class _LoadingScreenState extends State<LoadingScreen> {
//  @override
//  void initState() {
//    super.initState();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: Container(
//        child: Text(
//          "${widget.locationData}",
//          style: TextStyle(color: Colors.redAccent),
//        ),
//      ),
//    );
//  }
//}

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String firstButtonText = 'Take photo';
  String secondButtonText = 'Record video';
  double textSize = 20;
  String albumName = 'Media';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  void getLocation() async {
    print('Fetching Location');
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    print(position);

    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return HomeScreen(
        locationData: position,
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SpinKitWave(
            color: Colors.white,
            size: 50.0,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
              "Fetching Location Data \n Make sure Location and Data is turned on"),
        ],
      )),
    );
  }
}
