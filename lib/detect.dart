// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

// class ObjectDetectionCamera extends StatefulWidget {
//   final CameraDescription cameraDescription;
//   const ObjectDetectionCamera({Key? key, required this.cameraDescription})
//       : super(key: key);

//   @override
//   State<ObjectDetectionCamera> createState() => _ObjectDetectionCameraState();
// }

// class _ObjectDetectionCameraState extends State<ObjectDetectionCamera> {
//   late CameraController _controller;
//   late ObjectDetector _objectDetector;
//   bool _isDetecting = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeObjectDetector();  // load model and init detector
//     _initializeCamera();
//   }

//   // Initialize camera controller with correct format for each platform
//   Future<void> _initializeCamera() async {
//     _controller = CameraController(
//       widget.cameraDescription,
//       ResolutionPreset.high,
//       enableAudio: false,
//       imageFormatGroup: Platform.isAndroid 
//           ? ImageFormatGroup.nv21 
//           : ImageFormatGroup.bgra8888,
//     );
//     await _controller.initialize();
//     // Start image stream for real-time processing
//     _controller.startImageStream(_processCameraImage);
//     if (mounted) setState(() {});
//   }

//   // Load TFLite model from assets and configure ML Kit detector
//   Future<void> _initializeObjectDetector() async {
//     final modelPath = await _getModelPath('assets/model.tflite');
//     final options = LocalObjectDetectorOptions(
//       mode: DetectionMode.stream,
//       modelPath: modelPath,
//       classifyObjects: true,
//       multipleObjects: true,
//     );
//     _objectDetector = ObjectDetector(options: options);
//   }

//   // Helper to copy the asset model to a usable file path
//   Future<String> _getModelPath(String assetPath) async {
//     final appDir = await getApplicationSupportDirectory();
//     final modelFile = File('${appDir.path}/$assetPath');
//     await modelFile.parent.create(recursive: true);
//     if (!await modelFile.exists()) {
//       final byteData = await rootBundle.load(assetPath);
//       await modelFile.writeAsBytes(
//         byteData.buffer.asUint8List(),
//         flush: true,
//       );
//     }
//     return modelFile.path;
//   }

//   // Process each camera frame
//   void _processCameraImage(CameraImage image) async {
//     if (_isDetecting) return;
//     _isDetecting = true;
//     final inputImage = _inputImageFromCameraImage(image);
//     if (inputImage != null) {
//       final objects = await _objectDetector.processImage(inputImage);
//       for (final obj in objects) {
//         for (final label in obj.labels) {
//           print('Detected ${label.text} with confidence ${label.confidence}');
//         }
//       }
//     }
//     _isDetecting = false;
//   }

//   // Convert CameraImage to InputImage with proper rotation and format
//   InputImage? _convertCameraImage(CameraImage image) {
//     final sensorOrientation = widget.cameraDescription.sensorOrientation;
//     late InputImageRotation rotation;
//     if (Platform.isIOS) {
//       rotation = InputImageRotationValue.fromRawValue(sensorOrientation)!;
//     } else {
//       final deviceOrientation = _controller.value.deviceOrientation;
//       final orientationMap = <DeviceOrientation,int>{
//         DeviceOrientation.portraitUp: 0,
//         DeviceOrientation.landscapeLeft: 90,
//         DeviceOrientation.portraitDown: 180,
//         DeviceOrientation.landscapeRight: 270,
//       };
//       final rotationCompensation = orientationMap[deviceOrientation] ?? 0;
//       if (widget.cameraDescription.lensDirection == CameraLensDirection.front) {
//         rotation = InputImageRotationValue.fromRawValue(
//             (sensorOrientation + rotationCompensation) % 360)!;
//       } else {
//         rotation = InputImageRotationValue.fromRawValue(
//             (sensorOrientation - rotationCompensation + 360) % 360)!;
//       }
//     }
//     final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
//                    InputImageFormat.nv21;
//     final plane = image.planes.first;
//     final inputImage = InputImage.fromBytes(
//       bytes: plane.bytes,
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: format,
//         bytesPerRow: plane.bytesPerRow,
//       ),
//     );
//     return inputImage;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_controller.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     return CameraPreview(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _objectDetector.close();
//     super.dispose();
//   }
// }
