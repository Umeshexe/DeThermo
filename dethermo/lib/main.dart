import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _image;

  Future getImage(bool isCamera) async {
    XFile? image;
    if (isCamera) {
      image = await ImagePicker().pickImage(source: ImageSource.camera);
    } else {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    }

    setState(() {
      _image = image;
    });
  }

  Future<void> performTaskOnImage() async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/model.tflite');

      // Load and preprocess the image.
      final File imageFile = File(_image!.path);
      Uint8List imageBytes = await imageFile.readAsBytes();

// Compress the image
      imageBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 300,
        minWidth: 300,
        quality: 88,
        rotate: 180,
      );

      // Define the model's input details.
      final inputShape = interpreter.getInputTensors()[0].shape;
      final inputType = interpreter.getInputTensors()[0].type;

      // Create a 4-dimensional input tensor.
      var input = imageBytes.buffer.asUint8List().reshape(inputShape);

      // Define the output tensor shape.
      var output = interpreter.getOutputTensors()[0].shape;

      // Run inference.
      interpreter.run(input, output);

      // Print the output.
      print(output);

      interpreter.close();
    } catch (e) {
      print('Error initializing the interpreter or performing inference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text Identification"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration:
                  BoxDecoration(color: Color.fromRGBO(238, 255, 209, 1)),
              child: Text(
                'Drive App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('Gallery'),
              onTap: () {
                getImage(false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                getImage(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _image == null
            ? Container()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Image.file(
                      File(_image!.path),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: performTaskOnImage,
                    child: Text('Perform Task'),
                  ),
                ],
              ),
      ),
    );
  }
}
