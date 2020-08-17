import 'dart:io';

import 'package:cameraapp/components/bottom_button.dart';
import 'package:cameraapp/screens/screen1.dart';
import 'package:ftpclient/ftpclient.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:video_compress/video_compress.dart';

enum cameraMode { photo, video }

class UploadScreen extends StatefulWidget {
  UploadScreen({this.mediaFile, this.camMode, this.textFile});
  final File mediaFile;
  final File textFile;
  final int camMode;
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

String progressText = 'Ready to upload';

class _UploadScreenState extends State<UploadScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  cameraMode captureMode;
  bool _isUploading = false;
  File fileUpload, textFile;

  @override
  void initState() {
    super.initState();
    print('App initialized');
    setState(() {
      _isUploading = false;
      progressText = 'Ready to Upload';
    });
    captureMode = cameraMode.values[(widget.camMode)];
    fileUpload = widget.mediaFile;
    textFile = widget.textFile;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Camera+GPS'),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _isUploading ? CircularProgressIndicator() : Container(),
                  Text(progressText),
                ],
              ),
            )),
            progressText != 'Upload Completed!'
                ? BottomButton(
                    onTap: () {
                      if (_isUploading) {
                        _showMyDialog("Please wait", "Upload in progress");
                      } else {
                        if (captureMode == cameraMode.photo &&
                            fileUpload != null) {
                          setState(() {
                            _isUploading = true;
                          });
                          print("image uploading!");
                          ftpUpload(fileUpload, textFile, context);
                        } else if (captureMode == cameraMode.video &&
                            fileUpload != null) {
                          setState(() {
                            _isUploading = true;
                          });
                          print("video uploading!");
                          ftpUpload(fileUpload, textFile, context);
                        } else {
                          _showMyDialog('Nothing to upload!',
                              "Capture an Image/Video first");
                          print("nothing to upload!");
                        }
                      }
                    },
                    buttonTitle: _isUploading ? "Uploading..." : "Upload",
                  )
                : BottomButton(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return LoadingScreen();
                        }),
                        (Route<dynamic> route) => false,
                      );
                    },
                    buttonTitle: "New Complaint",
                  ),
          ],
        ));
  }

  void ftpUpload(File file, File textFile, BuildContext context) async {
    setState(() {
      _isUploading = true;
      progressText = 'Starting Upload...';
    });

    File fileToUpload;
    if (captureMode == cameraMode.video) {
      //Compression for Videos
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Compressing video..."),
      ));
      setState(() {
        progressText = 'Compressing Video...';
      });
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      fileToUpload = File(info.path);
      fileToUpload = fileToUpload.renameSync(//Renaming compressed video
          path.join(path.dirname(info.path), path.basename(file.path)));
      //_scaffoldKey.currentState.removeCurrentSnackBar();
      print(path.join(path.dirname(info.path), path.basename(file.path)));
//      _scaffoldKey.currentState.showSnackBar(SnackBar(
//        content: Text("Video compressed..."),
//      ));
      setState(() {
        _isUploading = true;
        progressText = 'Video Compressed';
      });
    } else {
      //For images
//      _scaffoldKey.currentState.showSnackBar(SnackBar(
//        content: Text("Connecting..."),
//      ));
      fileToUpload = file;
    }
    setState(() {
      progressText = 'Connecting...';
    });
    FTPClient ftpClient =
        FTPClient('182.50.151.114', user: 'pihms', pass: "MobApp@123\$");

    try {
//      _scaffoldKey.currentState.removeCurrentSnackBar();
//      _scaffoldKey.currentState.showSnackBar(SnackBar(
//        content: Text("Connecting..."),
//      ));
      ftpClient.connect();
//      _scaffoldKey.currentState.hideCurrentSnackBar();
      print("Connection Successful");
      setState(() {
        progressText = 'Connection Successful';
      });
//      _scaffoldKey.currentState.showSnackBar(SnackBar(
//        content: Text("Connection Successful"),
//      ));

      print(ftpClient.currentDirectory());
      ftpClient.changeDirectory(
          captureMode == cameraMode.photo ? 'images' : 'videos');
      print(ftpClient.currentDirectory());

//      _scaffoldKey.currentState.hideCurrentSnackBar();
//      _scaffoldKey.currentState.showSnackBar(SnackBar(
//        content: Text("Uploading..."),
//      ));
      setState(() {
        progressText = 'Uploading Text File...';
      });
      await ftpClient.uploadFile(textFile);
      print('TextFile Uploaded');
      setState(() {
        progressText = 'Uploading Media File...';
      });
      await ftpClient.uploadFile(fileToUpload).then((value) {
        Alert(
                context: context,
                title: "Upload Done!",
                desc: (captureMode == cameraMode.photo ? 'Image' : 'Video') +
                    ' was uploaded successfully.')
            .show();
//        _scaffoldKey.currentState.removeCurrentSnackBar();
//        _scaffoldKey.currentState.showSnackBar(SnackBar(
//          content: Text("Uploaded Successfully"),
//          action: SnackBarAction(
//            label: 'Done',
//            onPressed: () {},
//          ),
//        ));
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
      setState(() {
        progressText = 'Upload Completed!';
      });
      print("End FTP");
    }
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
}
