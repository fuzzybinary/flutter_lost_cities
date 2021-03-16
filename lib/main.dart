import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/camera_view.dart';
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isCameraOpen = false;

  bool _classifying = false;
  Classifier? _classifier;

  void _loadClassifier() async {
    _classifier = Classifier();
    await _classifier?.start();
  }

  void _onCameraButtonPressed() {
    setState(() {
      _isCameraOpen = !_isCameraOpen;
    });
  }

  void _onCameraData(CameraImage cameraImage) async {
    if (_classifier != null && _classifier!.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      await _classifier?.classify(cameraImage);

      _classifying = false;
    }
  }

  void _classifySample() async {
    if (_classifier != null && _classifier!.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      await _classifier?.classifyAsset('test_image.jpg');

      _classifying = false;
    }
  }

  @override
  void initState() {
    super.initState();

    _loadClassifier();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Container(
          child: _isCameraOpen
              ? CameraView(
                  onCameraData: _onCameraData,
                )
              : Column(children: [
                  Text('Camera is Off'),
                  ElevatedButton(
                    child: Text("Try the sample image."),
                    onPressed: _classifySample,
                  )
                ])),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera),
        onPressed: _onCameraButtonPressed,
      ),
    );
  }
}
