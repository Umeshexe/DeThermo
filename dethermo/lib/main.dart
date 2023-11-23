import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Import tflite_flutter
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Import flutter_image_compress

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Text Identification",
            style: TextStyle(
                color: const Color.fromARGB(255, 141, 0, 0),
                fontSize: 25,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          elevation: 5,
          shadowColor: Colors.blue,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.insert_drive_file),
                onPressed: () {
                  getImage(false); // gallery
                },
              ),
              SizedBox(height: 10.0),
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: () {
                  getImage(true);
                },
              ),
              _image == null
                  ? Container()
                  : Column(
                      children: <Widget>[
                        Image.file(
                          File(_image!.path),
                          height: 300.0,
                          width: 300.0,
                        ),
                        TextButton(
                          child: Text('Perform Task'),
                          onPressed: performTaskOnImage,
                        ),
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }
}
