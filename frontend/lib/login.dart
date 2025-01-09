import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memoir_lane/API/postgreSQL.dart';
import 'package:memoir_lane/diary.dart';
import 'package:memoir_lane/network.dart';
import 'package:memoir_lane/register.dart';
import 'package:memoir_lane/style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  XFile? imagePicked;
  String? imageValidator;
  bool loadingAction = false;
  bool isPasswordVisible = false;

  @override
  void initState() {
    print(ipAdress());
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    const emailPattern = r'^[a-zA-Z0-9]+([._%+-]?[a-zA-Z0-9]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasNumber) {
      return 'Password must have a letter and a number';
    }
    return null;
  }

  //face detector instance
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  // Detect face in the given image
  Future<bool> _detectFace(XFile xfile) async {
    final imageFile = File(xfile.path);
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty; // Return true if faces are detected
    } catch (e) {
      print("Error detecting face: $e");
      return false; // Return false if an error occurs or no face is detected
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            ListView(
              children: [
                PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) async {
                      if (didPop) {
                        return;
                      }
                    },
                    child: Container()),
                SizedBox(height: 100),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Image.asset('assets/diary check.png', scale: 2),
                        SizedBox(height: 30),
                        Text(
                          'Memoir Lane',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(hintText: 'Email'),
                                validator: _validateEmail,
                              ),
                              TextFormField(
                                controller: passController,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !isPasswordVisible,
                                validator: _validatePassword,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 50),
                        Container(
                          width: 150,
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                loadingAction = true;
                              });

                              //
                              if (_formKey.currentState!.validate()) {
                                final result = await loginUser(emailController.text, passController.text);
                                if (result['status'] == 'success') {
                                  int userId = int.parse(result['id']);
                                  print('Logged in successfully. User ID: $userId');
                                  // Navigate to another page or perform further actions
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Logged in successfully.'),
                                      backgroundColor: Colors.green,
                                      showCloseIcon: true,
                                    ),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DiaryPage(id: userId)),
                                  );
                                } else {
                                  // Login failed
                                  String errorMessage = result['message'];
                                  print('Login failed: $errorMessage');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                      showCloseIcon: true,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }

                              setState(() {
                                loadingAction = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 50),
                        Text(
                          'Or use face recognition to login.',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 30),
                        InkWell(
                            onTap: () async {
                              setState(() {
                                loadingAction = true;
                              });

                              //
                              final picker = ImagePicker();
                              final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
                              if (pickedFile != null) {
                                bool isFace = await _detectFace(pickedFile);
                                if (!isFace) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No face detected. Please upload a clear selfie.'),
                                      backgroundColor: Colors.red,
                                      showCloseIcon: true,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                } else {
                                  setState(() {
                                    imagePicked = pickedFile;
                                    imageValidator = null;
                                  });

                                  //
                                  // Convert the image to base64
                                  final bytes = await pickedFile.readAsBytes();
                                  final base64Image = base64Encode(bytes);

                                  final result = await compareFaces(base64Image);

                                  if (result['match']) {
                                    int userId = result['user_id'];
                                    print('Face match found, user ID: ${result['userId']}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Logged in successfully.'),
                                        backgroundColor: Colors.green,
                                        showCloseIcon: true,
                                      ),
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => DiaryPage(id: userId)),
                                    );
                                  } else {
                                    // If no match is found
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No face match found. Please try again.'),
                                        backgroundColor: Colors.red,
                                        showCloseIcon: true,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }

                              setState(() {
                                loadingAction = false;
                              });
                            },
                            child: imagePicked != null
                                ? Image.file(File(imagePicked!.path), width: 200)
                                : Image.asset('assets/faceDefault.png')),
                        SizedBox(height: 30),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account yet?',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (loadingAction) showLoadingAction(),
          ],
        ),
      ),
    );
  }
}
