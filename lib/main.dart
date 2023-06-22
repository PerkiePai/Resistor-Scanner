//app ui import

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
//camera encode import
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
//connection import
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final camera = cameras.first;

  runApp(MyApp(camera: camera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key key, this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resistor Scanner',
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({Key key, this.camera}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool flash = false;

  String watt = ''; //receive watt from python backend

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();

  }

  Future<void> _startStreaming() async {
    await _controller.startImageStream((CameraImage image) {
      String encodedFrame = _encodeFrame(image);
      print('get a frame!!');
      // Do something with the encoded frame
    });
  }

  String _encodeFrame(CameraImage image) {
    Uint8List bytes = image.planes[0].bytes;
    String encodedFrame = base64.encode(bytes);
    return encodedFrame;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.blue,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15))),
        // elevation: 0,
        title: const Text(
          'Resistor Scanner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {},
          icon: const Icon(Icons.settings, size: 20),
        ),
        actions: const [CreditIconButton()],
      ),
      body: Stack(
        // alignment: Alignment.topCenter,
        children: [
          Positioned(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          child: SizedOverflowBox(
                            size: const Size(300, 300),
                            alignment: Alignment.topCenter,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.65), BlendMode.srcOut),
                        child: Stack(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                  color: Colors.black,
                                  backgroundBlendMode: BlendMode.dstIn),
                              // This one will handle background + difference out
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 150),
                                    width: 225,
                                    height: 225,
                                    decoration: const BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Align(
                          alignment: Alignment.topCenter,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // a box used to put the fitted resistor
                              Container(
                                margin: const EdgeInsets.only(top: 249),
                                width: 50,
                                height: 27,
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                        color:
                                            const Color.fromARGB(100, 0, 0, 0),
                                        width: 2),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10))),
                              ),
                              //Left-side line aside the middle
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 262.5, left: 94),
                                width: 45,
                                height: 4,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Color.fromARGB(100, 0, 0, 0),
                                        width: 2),
                                  ),
                                ),
                              ),
                              //Right-side line aside the middle
                              Container(
                                margin: const EdgeInsets.only(
                                    top: 262.5, right: 94),
                                width: 45,
                                height: 4,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Color.fromARGB(100, 0, 0, 0),
                                        width: 2),
                                  ),
                                ),
                              ),
                              //Color band 1
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 251,
                                ),
                                width: 30,
                                height: 23,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                        color: Color.fromARGB(100, 0, 0, 0),
                                        width: 1.5),
                                    right: BorderSide(
                                        color: Color.fromARGB(100, 0, 0, 0),
                                        width: 1.5),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  children: [
                                    Text(
                                      ": $watt :",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        backgroundColor: Colors.transparent,
                                        fontSize: 40,
                                        fontFamily: 'Kanit',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: flash
              ? const Icon(Icons.flashlight_on)
              : const Icon(Icons.flashlight_off),
          onPressed: () {
            setState(() {
              flash = !flash;
            });
            flash
                ? _controller.setFlashMode(FlashMode.torch)
                : _controller.setFlashMode(FlashMode.off);
          }),
    );
  }
}

class CreditIconButton extends StatelessWidget {
  const CreditIconButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
            title: const Center(
              child: Text(
                'Credit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: const [
                  Text('-------------------------------------------\n'),
                  Text(
                    'Developer\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Karitt Thanawan\n'),
                  Text('-------------------------------------------\n'),
                  Text(
                    'Supporter-san\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('nfx\n'),
                  Text('meu\n'),
                  Text('hh\n'),
                  Text('-------------------------------------------\n'),
                  Text(
                    'Source Code Here\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //scr ( qrcode or github )
                ],
              ),
            ),
          ),
        );
      },
      icon: const Icon(
        Icons.help_outline_rounded,
        size: 20,
      ),
    );
  }
}
