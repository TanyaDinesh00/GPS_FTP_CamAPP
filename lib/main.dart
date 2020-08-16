import 'package:flutter/material.dart';
import 'screens/screen1.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: LoadingScreen(),
    );
  }
}
