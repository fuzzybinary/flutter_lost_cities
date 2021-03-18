import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';

typedef void OnCameraData(CameraImage cameraData);

class CameraView extends StatefulWidget {
  final OnCameraData onCameraData;
  final Widget? child;

  CameraView({Key? key, required this.onCameraData, this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;

  void _initializeCamera() async {
    var cameras = await availableCameras();
    if (cameras.isEmpty) return;

    var cameraController = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    await cameraController.initialize();

    // Stream of image passed to [onLatestImageAvailable] callback
    await cameraController.startImageStream(_onLatestImageAvailable);

    _cameraController = cameraController;

    // Update state to force a re-render
    setState(() {});
  }

  void _onLatestImageAvailable(CameraImage cameraImage) async {
    widget.onCameraData(cameraImage);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        _cameraController?.stopImageStream();
        break;
      case AppLifecycleState.inactive:
        _cameraController?.stopImageStream();
        _cameraController?.dispose();
        _cameraController = null;
        break;
      case AppLifecycleState.resumed:
        if (_cameraController != null) {
          await _cameraController?.startImageStream(_onLatestImageAvailable);
        } else {
          _initializeCamera();
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return CircularProgressIndicator();
    }

    //return CameraPlatform.instance.buildPreview(_cameraController!.cameraId);
    return CameraPreview(_cameraController!, child: widget.child);
  }
}
