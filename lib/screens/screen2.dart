import 'dart:io';

import 'package:cameraapp/screens/screen3.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:ftpclient/ftpclient.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../components/ButtonGroup.dart';
import '../components/bottom_button.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({this.locationData});
  final locationData;
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum cameraMode { photo, video }

class _HomeScreenState extends State<HomeScreen> {
  String albumName = 'Media';
  bool _isUploading = false;

  var location;
  cameraMode captureMode = cameraMode.photo;
  File _image, _video;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    location = widget.locationData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Camera+GPS "),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ButtonGroup(
                  titles: ["Photo", "Video"],
                  current: captureMode.index,
                  color: Colors.blue,
                  secondaryColor: Colors.white,
                  onTab: (selected) {
                    setState(() {
                      captureMode = cameraMode.values[selected];
                    });
                    print("$captureMode");
                  },
                ),
                RaisedButton(
                    child: Text("Capture"),
                    onPressed: () {
                      print("Button Pressed");
                      _capture();
                    }),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  if (_image != null && captureMode == cameraMode.photo)
                    Expanded(
                      child: Image.file(
                        _image,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if (_video != null && captureMode == cameraMode.video)
                    _videoPlayerController.value.initialized
                        ? Expanded(
                            child: Chewie(
                            controller: _chewieController,
                          ))
                        : Container(
                            child: Text(
                              "Waiting for video_player to be initialized...",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          )
                  else
                    Text(
                      "Click on capture to get started.",
                      style: TextStyle(fontSize: 18.0, color: Colors.blueGrey),
                    ),
                ],
              ),
            ),
            BottomButton(
              onTap: () {
                if (_isUploading) {
                  _showMyDialog("Please wait", "Upload in progress");
                } else {
                  if (captureMode == cameraMode.photo && _image != null) {
                    setState(() {
                      _isUploading = true;
                    });
                    print("image uploading!");
                    //ftpUpload(_image, context);
                    moveToUploadScreen(_image, captureMode);
                  } else if (captureMode == cameraMode.video &&
                      _video != null) {
                    setState(() {
                      _isUploading = true;
                    });
                    print("video uploading!");
                    //ftpUpload(_video, context);
                    moveToUploadScreen(_video, captureMode);
                  } else {
                    _showMyDialog(
                        'Nothing to upload!', "Capture an Image/Video first");
                    print("nothing to upload!");
                  }
                }
              },
              buttonTitle: _isUploading ? "Loading..." : "Next",
            ),
          ],
        ),
      ),
    );
  }

  void _capture() {
    if (captureMode == cameraMode.photo) {
      _takePhoto();
    }
    if (captureMode == cameraMode.video) {
      _recordVideo();
    }
  }

  void _takePhoto() async {
    await _picker
        .getImage(source: ImageSource.camera, imageQuality: 50)
        .then((PickedFile pickedFile) async {
      if (pickedFile != null && pickedFile.path != null) {
        print(pickedFile.path);
        String dir = (await getApplicationDocumentsDirectory()).path;
        var now = new DateTime.now();
        String timeStamp = DateFormat("yyyyMMddhhmmssmmm").format(now);
        var lat = double.parse(location.latitude.toString()).toStringAsFixed(5);
        var lon =
            double.parse(location.longitude.toString()).toStringAsFixed(5);
        String newPath = path.join(
            dir,
            'PIHMS' +
                '_' +
                lat.replaceAll('.', '') +
                lon.replaceAll('.', '') +
                '_' +
                timeStamp +
                path.extension(pickedFile.path));
//            .replaceAll(':', '-')
//            .replaceAll(' ', '_'); //No spaces for iOS

        File f = await File(pickedFile.path).copy(newPath);
        setState(() {
          _image = f;
        });
        _showMyDialog("Image saved", path.basename((f.path)));
        print(f.path);

        await GallerySaver.saveImage(
          f.path,
          albumName: albumName,
        ).then((bool success) {
          print("${f.path}");
        });
      }
    });
  }

  void _recordVideo() async {
    await _picker
        .getVideo(
      source: ImageSource.camera,
    )
        .then((PickedFile pickedFile) async {
      if (pickedFile != null && pickedFile.path != null) {
        print(pickedFile.path);
        String dir = (await getApplicationDocumentsDirectory()).path;
        var now = new DateTime.now();
        String timeStamp = DateFormat("yyyyMMddhhmmssmmm").format(now);
        var lat = double.parse(location.latitude.toString()).toStringAsFixed(5);
        var lon =
            double.parse(location.longitude.toString()).toStringAsFixed(5);
        String newPath = path.join(
            dir,
            'PIHMS' +
                '_' +
                lat.replaceAll('.', '') +
                lon.replaceAll('.', '') +
                '_' +
                timeStamp +
                '.mp4'); //+path.extension(pickedFile.path)
//            .replaceAll(':', '-')
//            .replaceAll(' ', '_'); //No spaces for iOS

        File f = await File(pickedFile.path).copy(newPath);
        setState(() {
          _video = f;
        });
        _videoPlayerController = VideoPlayerController.file(_video)
          ..initialize().then((_) {
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController,
                aspectRatio: _videoPlayerController.value.aspectRatio,
                autoPlay: true,
                looping: false,
              );
            });
          });
        _showMyDialog("Video saved", path.basename((f.path)));
        print(f.path);

        await GallerySaver.saveVideo(
          f.path,
          albumName: albumName,
        ).then((bool success) {
          print("${f.path}");
        });
      }
    });
  }

  Future<void> _showMyDialog(String a, String b) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$a'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('$b'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void ftpUpload(File file, BuildContext context) async {
    File fileToUpload;
    if (captureMode == cameraMode.video) {
      //Compression for Videos
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Compressing video..."),
      ));
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      fileToUpload = File(info.path);
      fileToUpload = fileToUpload.renameSync(//Renaming compressed video
          path.join(path.dirname(info.path), path.basename(file.path)));
      _scaffoldKey.currentState.removeCurrentSnackBar();
      print(path.join(path.dirname(info.path), path.basename(file.path)));
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Video compressed..."),
      ));
    } else {
      //For images
      setState(() {
        _isUploading = true;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Connecting..."),
      ));
      fileToUpload = file;
    }

    FTPClient ftpClient =
        FTPClient('182.50.151.114', user: 'pihms', pass: "MobApp@123\$");

    try {
      _scaffoldKey.currentState.removeCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Connecting..."),
      ));
      ftpClient.connect();
      _scaffoldKey.currentState.hideCurrentSnackBar();
      print("Connection Successful");
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Connection Successful"),
      ));

      print(ftpClient.currentDirectory());
      ftpClient.changeDirectory(
          captureMode == cameraMode.photo ? 'images' : 'videos');
      print(ftpClient.currentDirectory());

      _scaffoldKey.currentState.hideCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Uploading..."),
      ));
      await ftpClient.uploadFile(fileToUpload).then((value) {
        Alert(
                context: context,
                title: "Upload Done!",
                desc: (captureMode == cameraMode.photo ? 'Image' : 'Video') +
                    ' was uploaded successfully.')
            .show();
        _scaffoldKey.currentState.removeCurrentSnackBar();
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("Uploaded Successfully"),
          action: SnackBarAction(
            label: 'Done',
            onPressed: () {},
          ),
        ));
        print("Upload done!");
      });
    } catch (e) {
      Alert(context: context, title: "Error", desc: e.toString()).show();
      print(e);
      ftpClient.disconnect();
      setState(() {
        _isUploading = false;
      });
    } finally {
      _scaffoldKey.currentState.hideCurrentSnackBar();
      ftpClient.disconnect();
      setState(() {
        _isUploading = false;
      });
      print("End FTP");
    }
  }

  void moveToUploadScreen(File file, cameraMode captureMode) {
//    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
//      return UploadScreen(
//        fileToUpload: file,
//        camMode: captureMode.index,
//      );
//    }));
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return TestScreen(
        mediaFile: file,
        camMode: captureMode.index,
      );
    })).then((value) {
      setState(() {
        _isUploading = false;
      });
    });
  }
}
