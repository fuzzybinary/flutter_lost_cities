import 'package:flutter/material.dart';
import 'package:flutter_match/game_screen/game_screen.dart';
import 'package:flutter_match/network/network_service.dart';
import 'package:flutter_match/tflite/classifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    this.title,
  }) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Classifier _classifier = Classifier();
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();

    _loadClassifier();
  }

  void _loadClassifier() {
    _classifier.start();
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(_classifier, _networkService);
  }
}
