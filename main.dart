import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// For mobile only
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras only for mobile
  if (!kIsWeb) {
    cameras = await availableCameras();
  }

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const HomeRoute(),
      '/second': (context) => const SecondRoute(),
      '/third': (context) => const ThirdRoute(),
    },
  ));
}

class HomeRoute extends StatelessWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Verification'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Start Face Verification'),
              onPressed: () {
                Navigator.pushNamed(context, '/second');
              },
            ),
            ElevatedButton(
              child: const Text('Other Action'),
              onPressed: () {
                Navigator.pushNamed(context, '/third');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({super.key});

  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  void initState() {
    super.initState();

    // Only initialize camera for mobile
    if (!kIsWeb) {
      _controller = CameraController(
        cameras[0], // Select the first camera (usually front-facing)
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize();
    }
  }

  @override
  void dispose() {
    // Only dispose of the controller if it's initialized on mobile
    if (!kIsWeb) {
      _controller.dispose();
    }
    super.dispose();
  }

  // Function to verify a face using camera-captured image (for mobile)
  Future<void> _takePictureAndVerify() async {
    if (kIsWeb) return; // Skip this function on the web

    try {
      await _initializeControllerFuture;

      // Take a picture and get the file location.
      final image = await _controller.takePicture();

      setState(() {
        _isProcessing = true;
      });

      bool isVerified = await _verifyFace(File(image.path));

      if (isVerified) {
        _showDialog('Verification Success', 'Face verified successfully!');
      } else {
        _showDialog(
            'Verification Failed', 'Face verification failed. Try again.');
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      _showDialog('Error', 'Something went wrong: $e');
    }
  }

  // Function to verify a face using a picked image (for both mobile and web)
  Future<void> _pickImageAndVerify() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _isProcessing = true;
        });

        bool isVerified = await _verifyFace(File(pickedFile.path));

        if (isVerified) {
          _showDialog('Verification Success', 'Face verified successfully!');
        } else {
          _showDialog('Verification Failed', 'Face verification failed.');
        }

        setState(() {
          _isProcessing = false;
        });
      } else {
        _showDialog('Error', 'No image selected.');
      }
    } catch (e) {
      _showDialog('Error', 'Something went wrong: $e');
    }
  }

  // Function to send the image for face verification
  Future<bool> _verifyFace(File imageFile) async {
    // Example URL for face verification API (replace with actual API)
    const apiUrl = 'https://your-face-verification-api.com/verify';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    // Send the request to the API
    final response = await request.send();

    if (response.statusCode == 200) {
      // Parse response (assuming JSON format)
      var responseBody = await http.Response.fromStream(response);
      var jsonResponse = json.decode(responseBody.body);

      // Assuming the API returns a "verified" field
      return jsonResponse['verified'] ?? false;
    } else {
      return false;
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Verification"),
        backgroundColor: Colors.green,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!kIsWeb) ...[
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_controller);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _takePictureAndVerify,
                    child: const Text('Take Picture and Verify Face'),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImageAndVerify,
                  child: const Text('Upload Picture and Verify Face'),
                ),
              ],
            ),
    );
  }
}

class ThirdRoute extends StatelessWidget {
  const ThirdRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Other Action"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text('This is another action page'),
      ),
    );
  }
}
