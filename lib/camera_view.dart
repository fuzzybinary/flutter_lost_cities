import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

typedef OnCameraData = void Function(CameraImage cameraData);

class CameraView extends StatefulWidget {
  final OnCameraData onCameraData;
  final Widget? child;
  final bool isStreaming;

  const CameraView(
      {Key? key,
      required this.onCameraData,
      required this.isStreaming,
      this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initCameraFuture;

  Future<void> _initializeCamera() async {
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

    _initCameraFuture = _initializeCamera();
  }

  @override
  void didUpdateWidget(CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isStreaming && !oldWidget.isStreaming) {
      _cameraController?.startImageStream(_onLatestImageAvailable);
      _cameraController?.resumePreview();
    } else if (!widget.isStreaming && oldWidget.isStreaming) {
      _cameraController?.stopImageStream();
      _cameraController?.pausePreview();
    }
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
    return FutureBuilder(
      future: _initCameraFuture!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(_cameraController!, child: widget.child);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
