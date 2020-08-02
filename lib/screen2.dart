import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:ftpconnect/ftpconnect.dart';

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

  var location;
  int index = 0;
  File _image, _video;
  VideoPlayerController _videoPlayerController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    location = widget.locationData;
  }

  @override
  Widget build(BuildContext context) {
//    return Scaffold(
//      body: Container(
//        color: Colors.white,
//        child: Column(
//          children: <Widget>[
//            Flexible(
//              flex: 1,
//              child: Container(
//                child: SizedBox.expand(
//                  child: RaisedButton(
//                    color: Colors.blue,
//                    onPressed: _takePhoto,
//                    child: Text(firstButtonText,
//                        style:
//                            TextStyle(fontSize: textSize, color: Colors.white)),
//                  ),
//                ),
//              ),
//            ),
//            Flexible(
//              child: Container(
//                  child: SizedBox.expand(
//                child: RaisedButton(
//                  color: Colors.white,
//                  onPressed: _recordVideo,
//                  child: Text(secondButtonText,
//                      style: TextStyle(
//                          fontSize: textSize, color: Colors.blueGrey)),
//                ),
//              )),
//              flex: 1,
//            )
//          ],
//        ),
//      ),
//    );
    return Scaffold(
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
              onTap: ftpt,
              buttonTitle: "Upload",
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
        String newPath = path.join(
            dir,
            location.toString() +
                "_" +
                DateTime.now().toString() +
                path.extension(pickedFile.path));
        File f = await File(pickedFile.path).copy(newPath);
        setState(() {
          _image = f;
        });
        _showMyDialog("Image", path.basename((f.path)));
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
        setState(() {
          _video = f;
        });
        _videoPlayerController = VideoPlayerController.file(_video)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController.play();
          });
        _showMyDialog("Video", path.basename((f.path)));
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

  Future<void> _showMyDialog(String a, String b) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$a Saved'),
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

//  void ftpTest() {
//    FTPClient ftpClient =
//        FTPClient('182.50.151.114', user: 'pihms', pass: "MobApp@123\$");
//
//    ftpClient.connect();
//
//    try {
//      print("Connection Succcessful");
//      print(ftpClient.currentDirectory());
//      ftpClient.changeDirectory('images');
//      print(ftpClient.currentDirectory());
//      ftpClient.uploadFile(File('test3.txt'));
//      ftpClient.uploadFile(_image);
//      print(ftpClient.listDirectoryContent());
//
//      //ftpClient.uploadFile(_image == null ? File('test1.zip') : _image);
//      print("End ftp");
//      //print(ftpClient.listDirectoryContent());
//
//    } finally {
//      // Disconnect
//      ftpClient.disconnect();
//    }
//  }
  void ftpt() async {
    FTPConnect ftpConnect =
        FTPConnect('182.50.151.114', user: 'pihms', pass: "MobApp@123\$");
    try {
      print("FTP. . .");
      await ftpConnect.connect();
      print("Connected");
      print(await ftpConnect.currentDirectory());

      print('Compressing file ...');

      File fileToCompress = _image;
//      final zipPath = (await getTemporaryDirectory()).path +
//          '/' +
//          path.basenameWithoutExtension(fileToCompress.path) +
//          '.zip';
      final zipPath = (await getTemporaryDirectory()).path +
          '/' +
          'Lat-12.903865_Long-77.599525_2020-08-02 10.41.46.690251' +
//          'Lat: 12.903865, Long: 77.599525_2020-08-02 10:41:46.690251' +
          '.zip';
      print(zipPath);
      await FTPConnect.zipFiles([fileToCompress.path], zipPath);
      await ftpConnect.changeDirectory('images');
      print(await ftpConnect.currentDirectory());

//      File fileToUpload = await _fileMock(
//          fileName: 'uploadStepByStep.txt', content: 'uploaded Step By Step');
//      print('Uploading ...');
//      await ftpConnect.uploadFile(fileToUpload);

      print('Uploading Zip file ...');
      bool res = await ftpConnect.uploadFile(File(zipPath));
      print('Zip file uploaded: ' + (res ? 'SUCCESSFULLY' : 'FAILED'));
      print("Upload Done!");
      print(await ftpConnect.currentDirectory());

      //print(await ftpConnect.listDirectoryContent());
      print("Done");
      await ftpConnect.disconnect();
    } catch (e) {
      print(e);
    }
  }

  Future<File> _fileMock({fileName = 'FlutterTest.txt', content = ''}) async {
    final Directory directory =
        Directory((await getExternalStorageDirectory()).path + '/test')
          ..createSync(recursive: true);
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }
}
