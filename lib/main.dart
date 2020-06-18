import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:async';
import 'package:dio/dio.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
  final String modeCamera = 'camera';
  final String modeGallery = 'gallery';

  File pickedImage;

  var text = '';
  var imglabels = [];
  var conf = [];
  var awaitImage;
  bool _isImageLoaded = false;
  bool _isLoading = false;

  Future<void> pickImage(String mode) async {
    if (mode.contains(modeGallery))
      awaitImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    else if (mode.contains(modeCamera))
      awaitImage = await ImagePicker.pickImage(source: ImageSource.camera);
    if (awaitImage == null)
      setState(() {
        text = 'No image selected';
        //return;
      });
    else {
      setState(() {
        _isLoading = true;
      });

      setState(() {
        pickedImage = awaitImage;
        _isImageLoaded = true;
        text = '';
      });

      FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(pickedImage);

      final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
      final List<ImageLabel> labels = await labeler.processImage(visionImage);

      for (ImageLabel imageLabel in labels) {
        final double confidence = imageLabel.confidence;
        setState(() {
          _isLoading = false;

          if (imglabels == null) {
            imglabels = [imageLabel.text];
            conf = [confidence.toStringAsFixed(2)];
          } else {
            imglabels.add(imageLabel.text);
            conf.add(confidence.toStringAsFixed(2));
          }

          text =
              '$text ${imageLabel.text}  ${confidence.toStringAsFixed(2)} \n';
        });
      }
      labeler.close();
    }
  }

  showDialog() {
    return AlertDialog(
        content: Column(
      children: [
        ...imglabels.map((e) => ListTile(
              title: Text(e),
            ))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Labeller"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _isImageLoaded
                    ? Expanded(
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(blurRadius: 20),
                                ]),
                            height: 250,
                            child: Image.file(
                              pickedImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Container(),
                Center(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            IconButton(
                              onPressed: () async {
                                imglabels = [];
                                pickImage(modeGallery);
                              },
                              
                              icon: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Select from gallery'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            IconButton(
                              onPressed: () async {
                                imglabels = [];
                                pickImage(modeCamera);
                              },
                              icon: Icon(
                                Icons.camera,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Capture Image'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ...imglabels.map((e) => ListTile(title: Text(e)))
                GestureDetector(
                  child: Container(
                    child: Text(
                      "Show Labels",
                      style: TextStyle(fontSize: 30.0),
                    ),
                    margin: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    alignment: Alignment.center,
                    height: 80.0,
                    width: 300.0,
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LabelPage(imglabels)));
                  },
                )
              ],
            ),
    );
  }
}

class LabelPage extends StatelessWidget {
  LabelPage(this.labels);
  final List labels;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Labels")),
        body: Column(
          children: [
            ...labels.map((e) => ListTile(
                  title: Text(e),
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Search(e.toString())));
                  },
                ))
          ],
        ));
  }
}

class Search extends StatelessWidget {
  Search(this.searchText);
  final String searchText;

  final Dio dio = new Dio();
  Response response;
  var url = "http://skullycoder1709.pythonanywhere.com/wiki/getInfo";
  List<String> rec = [];

  Future<String> _sendInfo(text) async {
    response = await dio.post(url, data: {"name": text});
    return response.data["info"].toString();
  }

  Widget showInfo(text) {
    return FutureBuilder(
      future: _sendInfo(text),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.data != null) {
          return Container(
            padding: EdgeInsets.all(12.0),
            child: Text(
              snapshot.data,
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [CircularProgressIndicator()],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$searchText'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            showInfo(searchText)
          ],
        ),
      ),
    );
  }
}