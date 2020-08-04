import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftpclient/ftpclient.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:video_player/video_player.dart';

import 'components/ButtonGroup.dart';
import 'components/bottom_button.dart';

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
  bool _isUploading = false;

  var location;
  int index = 0;
  File _image, _video;
  VideoPlayerController _videoPlayerController;

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
//                ReusableCard(text: firstButtonText + " " + secondButtonText),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ButtonGroup(
                  titles: ["Photo", "Video"],
                  current: index,
                  color: Colors.blue,
                  secondaryColor: Colors.white,
                  onTab: (selected) {
                    setState(() {
                      index = selected;
                    });
                    print("$index");
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    if (_image != null && index == 0)
                      Image.file(
                        _image,
                        fit: BoxFit.contain,
                      )
                    else if (_video != null && index == 1)
                      _videoPlayerController.value.initialized
                          ? AspectRatio(
                              aspectRatio:
                                  _videoPlayerController.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController),
                            )
                          : Container(
                              child: Text(
                                "Waiting for video_player to be initialized...",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            )
                    else
                      Text(
                        "Click on capture to get started.",
                        style:
                            TextStyle(fontSize: 18.0, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ),
            ),
            BottomButton(
              onTap: () {
                if (_isUploading) {
                  _showMyDialog("Please wait", "Upload in progress");
                } else {
                  if (index == 0 && _image != null) {
                    setState(() {
                      _isUploading = true;
                    });
                    print("image uploading!");
                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: Text("Connecting..."),
                    ));
                    ftpTest(_image, context);
                  } else if (index == 1 && _video != null) {
                    setState(() {
                      _isUploading = true;
                    });
                    print("video uploading!");
                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: Text("Connecting..."),
                    ));
                    ftpTest(_video, context);
                  } else {
                    _showMyDialog(
                        'Nothing to upload!', "Capture an Image/Video first");
                    print("nothing to upload!");
                  }
                }
              },
              buttonTitle: _isUploading ? "Uploading..." : "Upload",
            ),
          ],
        ),
      ),
    );
  }

  void _capture() {
    if (index == 0) {
      _takePhoto();
    }
    if (index == 1) {
      _recordVideo();
    }
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
        String newPath = path
            .join(
                dir,
                location.toString() +
                    "_" +
                    DateTime.now().toString() +
                    path.extension(pickedFile.path))
            .replaceAll(':', '-');
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
          setState(() {
            firstButtonText = 'image saved!';
          });
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
        setState(() {
          secondButtonText = 'saving in progress...';
        });

        print(pickedFile.path);
        String dir = (await getApplicationDocumentsDirectory()).path;
        String newPath = path
            .join(
                dir,
                location.toString() +
                    "_" +
                    DateTime.now().toString() +
                    path.extension(pickedFile.path))
            .replaceAll(':', '-');
        File f = await File(pickedFile.path).copy(newPath);
        setState(() {
          _video = f;
        });
        _videoPlayerController = VideoPlayerController.file(_video)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.play();
          });
        _showMyDialog("Video saved", path.basename((f.path)));
        print(f.path);

        await GallerySaver.saveVideo(
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

  void ftpTest(File fileToUpload, BuildContext context) async {
    FTPClient ftpClient =
        FTPClient('182.50.151.114', user: 'pihms', pass: "MobApp@123\$");

    try {
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
      ftpClient.changeDirectory(index == 0 ? 'images' : 'videos');
      print(ftpClient.currentDirectory());

      _scaffoldKey.currentState.hideCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Uploading..."),
      ));
      await ftpClient.uploadFile(fileToUpload).then((value) {
        Alert(
                context: context,
                title: "Upload Done!",
                desc: (index == 0 ? 'Image' : 'Video') +
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
    } finally {
      _scaffoldKey.currentState.hideCurrentSnackBar();
      ftpClient.disconnect();
      setState(() {
        _isUploading = false;
      });
      print("End FTP");
    }
  }
}
