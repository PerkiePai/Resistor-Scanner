//app ui import
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
//camera encode import
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

//connection import
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final camera = cameras.first;

  runApp(MyApp(camera: camera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

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

  const MyHomePage({Key? key, required this.camera}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool flash = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

String responseWatt = '';
final url = 'https://f430-2403-6200-8860-9f42-e8db-7a7d-3e59-129c.ngrok-free.app/server';

Future<void> sendBase64ToServer(String pictureBase64) async {
  try {
    final response = await http.post(
      Uri.parse(url),
      body: {'picture': pictureBase64},
    );
    log('base64ImageSent');
    if (response.statusCode == 200) {
      setState(() {
        responseWatt = response.body;
      });
    } else {
      setState(() {
        responseWatt = 'Error: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      responseWatt = 'Error: $e';
    });
  }
}

  // Future<String> getJsonFromServer(String responseWatt) async {
  //   try {
  //     final responseWatt = http.get(url as Uri);
  //   } catch (e) {
  //     setState(() {});
  //   }
  //   return responseWatt;
  // }

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
                            child: LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  bool isCaptureInProgress =
                                      false; // Declare the flag outside the function or make it static if needed

                                  Future<void> captureWithDelay() async {
                                    if (!_controller.value.isRecordingVideo &&
                                        !isCaptureInProgress) {
                                      isCaptureInProgress =
                                          true; // Set flag to true before capturing
                                      try {
                                        await _initializeControllerFuture;
                                        // Capture the frame as an image.
                                        final image =
                                            await _controller.takePicture();
                                        // Convert the image to Base64 JPEG format.
                                        final bytes = await image.readAsBytes();
                                        final base64Image = base64Encode(bytes);
                                        sendBase64ToServer(base64Image);
                                        
                                      } catch (e) {
                                        // Handle any exceptions that occur during capture
                                      }
                                      isCaptureInProgress =
                                          false; // Reset flag after capturing
                                    }
                                  }

// Define the delay duration (2 seconds in this case)
                                  const Duration captureDelay =
                                      Duration(seconds: 2);

// Function to start capturing periodically with an accurate delay
                                  Future<void>
                                      startCapturePeriodically() async {
                                    while (true) {
                                      await Future.delayed(captureDelay);
                                      await captureWithDelay();
                                    }
                                  }

// Call this function to start the periodic capture process
                                  startCapturePeriodically();
                                });

                                return CameraPreview(_controller);
                              },
                            ),
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
                                      ": $responseWatt :",
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
  const CreditIconButton({Key? key}) : super(key: key);

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
            content: const Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
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
