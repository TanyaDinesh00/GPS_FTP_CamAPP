import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  HomeScreen({this.locationData});
  final locationData;
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstButtonText = 'Take photo';
  String secondButtonText = 'Record video';
  double textSize = 20;
  String albumName = 'Media';

  var location;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    location = widget.locationData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Flexible(
              flex: 1,
              child: Container(
                child: SizedBox.expand(
                  child: RaisedButton(
                    color: Colors.blue,
                    onPressed: _takePhoto,
                    child: Text(firstButtonText,
                        style:
                            TextStyle(fontSize: textSize, color: Colors.white)),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Container(
                  child: SizedBox.expand(
                child: RaisedButton(
                  color: Colors.white,
                  onPressed: _recordVideo,
                  child: Text(secondButtonText,
                      style: TextStyle(
                          fontSize: textSize, color: Colors.blueGrey)),
                ),
              )),
              flex: 1,
            )
          ],
        ),
      ),
    );
  }

  void _takePhoto() async {
    await _picker
        .getImage(source: ImageSource.camera)
        .then((PickedFile pickedFile) async {
      if (pickedFile != null && pickedFile.path != null) {
        setState(() {
          firstButtonText = 'saving in progress...';
        });

        print(pickedFile.path);
        String dir = (await getApplicationDocumentsDirectory()).path;
        String newPath = path.join(
            dir,
            location.toString() +
                "_" +
                DateTime.now().toString() +
                path.extension(pickedFile.path));
        File f = await File(pickedFile.path).copy(newPath);
        print(f.path);

        GallerySaver.saveImage(
          f.path,
          albumName: albumName,
        ).then((bool success) {
          print("${f.path}");
          setState(() {
            firstButtonText = 'image saved!';
          });
        });
      }
    });
  }

  void _recordVideo() async {
    await _picker
        .getVideo(source: ImageSource.camera)
        .then((PickedFile pickedFile) async {
      if (pickedFile != null && pickedFile.path != null) {
        setState(() {
          secondButtonText = 'saving in progress...';
        });

        print(pickedFile.path);
        String dir = (await getApplicationDocumentsDirectory()).path;
        String newPath = path.join(
            dir,
            location.toString() +
                "_" +
                DateTime.now().toString() +
                path.extension(pickedFile.path));
        File f = await File(pickedFile.path).copy(newPath);
        print(f.path);

        GallerySaver.saveVideo(
          f.path,
          albumName: albumName,
        ).then((bool success) {
          print("${f.path}");
          setState(() {
            secondButtonText = 'Video saved!';
          });
        });
      }
    });
  }
}
