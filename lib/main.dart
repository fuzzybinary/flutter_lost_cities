import 'package:flutter/material.dart';
import 'package:flutter_match/game_screen/game_screen.dart';
import 'package:flutter_match/tflite/classifier.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Classifier _classifier = Classifier();

  @override
  void initState() {
    super.initState();

    _loadClassifier();
  }

  void _loadClassifier() async {
    await _classifier.start();
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(_classifier);
  }
}
