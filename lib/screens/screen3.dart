import 'dart:io';
import 'package:cameraapp/components/bottom_button.dart';
import 'package:cameraapp/screens/screen4.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TestScreen extends StatefulWidget {
  TestScreen({this.mediaFile, this.camMode});
  final File mediaFile;
  final int camMode;
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  File textFile;

  String selectedUser = 'Server Down';
  String holder = '';
  List<String> users = [
    'Slow Internet',
    'PDF not uploaded',
    'Camera defect',
    'Upload time exceeded',
    'Server Down'
  ];
  final myController = TextEditingController();
  final descController = TextEditingController();
  String complaintType;
  String problemType = 'Server Down';
  String description;

  cameraMode captureMode;
  File mediaFile;

  @override
  void initState() {
    super.initState();
    captureMode = cameraMode.values[(widget.camMode)];
    mediaFile = widget.mediaFile;
  }

  @override
  void dispose() {
    myController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera+GPS'),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFDEF2FF),
                      ),
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: myController,
                            decoration: InputDecoration(
                              hintText: 'Complaint Title',
                            ),
                          ),
                          DropdownButton<String>(
                            isExpanded: true,
                            hint: Text("Select item"),
                            value: selectedUser,
                            onChanged: (String value) {
                              setState(() {
                                selectedUser = value;
                                problemType = selectedUser.toString();
                              });
                            },
                            items: users.map((String user) {
                              return DropdownMenuItem<String>(
                                value: user,
                                child: Text(user),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0xFFDEF2FF),
                        ),
                        child: TextField(
                          controller: descController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Description',
                          ),
                        )),
                  ],
                ),
              ),
            ),
            BottomButton(
                onTap: () async {
                  print('Next Button Pressed');
                  complaintType = myController.text;
                  description = descController.text;
                  await _write(complaintType, problemType, description);

                  if (textFile != null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return UploadScreen(
                          mediaFile: mediaFile,
                          textFile: textFile,
                          camMode: captureMode.index,
                        );
                      }),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                buttonTitle: 'Next'),
          ],
        ),
      ),
    );
  }

  _write(String complaintTitle, String problemType, String description) async {
    String text;
    final Directory directory = await getApplicationDocumentsDirectory();
    textFile = File('${directory.path}/' +
        path.basenameWithoutExtension(widget.mediaFile.path) +
        '.txt');
    await textFile.writeAsString('ComplaintTitle:\n' +
        complaintTitle +
        '\nProblemType:\n' +
        problemType +
        '\nDescription:\n' +
        description);
    text = await textFile.readAsString();
    print(text);
    print(textFile.path);
  }
}
