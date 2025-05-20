// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:objdet/detect.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final cameras = await availableCameras();
//   runApp(MaterialApp(
//     home: ObjectDetectionCamera(cameraDescription: cameras.first),
//   ));
// }

// import 'dart:io';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';

// List<CameraDescription> _cameras = [];

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   _cameras = await availableCameras();
//   runApp(MaterialApp(home: ObjectDetectionScreen()));
// }

// class ObjectDetectionScreen extends StatefulWidget {
//   @override
//   State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
// }

// class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
//   late CameraController _controller;
//   late ObjectDetector _objectDetector;
//   bool _isBusy = false;
//   bool _isDetectorInitialized = false;

//   final Map<DeviceOrientation, int> _orientations = {
//     DeviceOrientation.portraitUp: 0,
//     DeviceOrientation.landscapeLeft: 90,
//     DeviceOrientation.portraitDown: 180,
//     DeviceOrientation.landscapeRight: 270,
//   };

//   @override
//   void initState() {
//     super.initState();
//     _initializeCameraAndModel();
//   }

//   Future<void> _initializeCameraAndModel() async {
//     final modelPath = await _getModelPath('assets/model.tflite');
//     final options = LocalObjectDetectorOptions(
//       mode: DetectionMode.stream,
//       modelPath: modelPath,
//       classifyObjects: true,
//       multipleObjects: true,
//     );

//     _objectDetector = ObjectDetector(options: options);
//     _isDetectorInitialized = true;

//     _controller = CameraController(
//       _cameras.firstWhere(
//           (camera) => camera.lensDirection == CameraLensDirection.back),
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );

//     await _controller.initialize();
//     _controller.startImageStream(_processCameraImage);
//     setState(() {});
//   }

//   Future<String> _getModelPath(String asset) async {
//     final path = '${(await getApplicationSupportDirectory()).path}/$asset';
//     final file = File(path);
//     if (!await file.exists()) {
//       final byteData = await rootBundle.load(asset);
//       await file.create(recursive: true);
//       await file.writeAsBytes(
//         byteData.buffer
//             .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
//       );
//     }
//     return file.path;
//   }

//   void _processCameraImage(CameraImage image) async {
//     if (!_isDetectorInitialized || _isBusy) return;
//     debugPrint("Image format: ${image.format.group}"); // Add this line to inspect
//     _isBusy = true;

//     final inputImage = _inputImageFromCameraImage(image);
//     if (inputImage == null) {
//       _isBusy = false;
//       return;
//     }

//     try {
//       final objects = await _objectDetector.processImage(inputImage);
//       for (final object in objects) {
//         debugPrint('Detected: ${object.labels.map((e) => e.text).join(", ")}');
//       }
//     } catch (e) {
//       debugPrint('Detection error: $e');
//     }

//     _isBusy = false;
//   }

//   InputImage? _inputImageFromCameraImage(CameraImage image) {
//     final camera = _cameras.first;
//     final sensorOrientation = camera.sensorOrientation;
//     int? rotationCompensation =
//         _orientations[_controller.value.deviceOrientation];
//     if (rotationCompensation == null) return null;

//     if (camera.lensDirection == CameraLensDirection.front) {
//       rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
//     } else {
//       rotationCompensation =
//           (sensorOrientation - rotationCompensation + 360) % 360;
//     }

//     final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
//     if (rotation == null) return null;

//     final format = InputImageFormatValue.fromRawValue(image.format.raw);
//     if (format == null) return null;

//     final WriteBuffer allBytes = WriteBuffer();
//     for (final plane in image.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();

//     final Size imageSize =
//         Size(image.width.toDouble(), image.height.toDouble());

//     final inputImageData = InputImageMetadata(
//       size: imageSize,
//       rotation: rotation,
//       format: format,
//       bytesPerRow: image.planes.first.bytesPerRow,
//     );

//     return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _objectDetector.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Offline Object Detection")),
//       body: _controller.value.isInitialized
//           ? CameraPreview(_controller)
//           : Center(child: CircularProgressIndicator()),
//     );
//   }
// }



import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  late ObjectDetector _objectDetector;
  bool _isBusy = false;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _objectDetector.close();
    super.dispose();
  }

  Future<void> _initializeCameraAndModel() async {
    _cameras = await availableCameras();
    final camera = _cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await _controller.initialize();
    _isControllerInitialized = true;

    _controller.startImageStream((CameraImage image) {
      if (_isBusy) return;
      _isBusy = true;
      _processCameraImage(image);
    });

    final modelPath = 'assets/model.tflite'; // put your model under assets
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.stream,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );

    _objectDetector = ObjectDetector(options: options);

    if (mounted) {
      setState(() {}); // Refresh UI after init
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final rotation = InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint("Unsupported format: ${image.format.raw}");
        return;
      }

      final plane = image.planes.first;
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final objects = await _objectDetector.processImage(inputImage);
      for (final object in objects) {
        debugPrint("Object: ${object.labels.map((e) => e.text).join(', ')}");
      }
    } catch (e) {
      debugPrint("Detection error: $e");
    } finally {
      _isBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Object Detection")),
      body: _isControllerInitialized
          ? CameraPreview(_controller)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
