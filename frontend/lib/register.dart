import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memoir_lane/API/postgreSQL.dart';
import 'package:memoir_lane/login.dart';
import 'package:image/image.dart' as img;
import 'package:memoir_lane/style.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  XFile? imagePicked;
  String? imageValidator;
  bool loadingAction = false;
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^0\d{10}$').hasMatch(value)) {
      return 'Must start with 0 and with 11 digits';
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

  //compress image
  Uint8List? compressImage(Uint8List imageBytes, {int quality = 70}) {
    // Decode the image from the provided bytes
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      return null; // Return null if the image cannot be decoded
    }

    img.Image resizedImage = img.copyResize(image, width: 700);

    // Encode the image to JPEG format with a specified quality
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
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
                SizedBox(height: 50),
                Container(
                  alignment: Alignment.center,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Image.asset('assets/diary check.png', scale: 2),
                        SizedBox(height: 20),
                        Text(
                          'Registration',
                          style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 30),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: passwordController,
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
                              SizedBox(height: 20),
                              TextFormField(
                                controller: confirmPasswordController,
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !isConfirmPasswordVisible,
                                validator: _validateConfirmPassword,
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: phoneController,
                                decoration: InputDecoration(
                                  hintText: 'Phone Number',
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 11,
                                validator: _validatePhone,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Register your face here:',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 20),
                        InkWell(
                            onTap: () async {
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
                                }
                              }
                            },
                            child: imagePicked != null
                                ? Image.file(File(imagePicked!.path), width: 200)
                                : Image.asset('assets/faceDefault.png')),
                        imageValidator == null
                            ? SizedBox()
                            : Text(
                                imageValidator!,
                                style: TextStyle(color: Colors.red),
                              ),
                        SizedBox(height: 20),
                        Container(
                          width: 150,
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                loadingAction = true;
                              });

                              //
                              if (imagePicked == null) {
                                setState(() {
                                  imageValidator = 'Face capture is required';
                                });
                              }
                              //
                              if (_formKey.currentState!.validate()) {
                                String emailResult = await checkEmail(emailController.text);
                                if (emailResult == 'success') {
                                  String phoneResult = await checkPhone(phoneController.text);
                                  if (phoneResult == 'success') {
                                    if (imagePicked == null) {
                                      setState(() {
                                        imageValidator = 'Face capture is required';
                                      });
                                    } else {
                                      Uint8List? picture;
                                      Uint8List originalBytes = await imagePicked!.readAsBytes();
                                      picture = compressImage(originalBytes); // Compress the image
                                      String result = await createAcc(emailController.text, passwordController.text,
                                          phoneController.text, picture!);
                                      if (result == 'success') {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Successfully Registered'),
                                          backgroundColor: Colors.green,
                                          showCloseIcon: true,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                        //navigate to login
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(result),
                                          backgroundColor: Colors.red,
                                          showCloseIcon: true,
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(phoneResult),
                                      backgroundColor: Colors.red,
                                      showCloseIcon: true,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(emailResult),
                                    backgroundColor: Colors.red,
                                    showCloseIcon: true,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }

                              setState(() {
                                loadingAction = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.deepPurple.withAlpha(200), borderRadius: BorderRadius.circular(5)),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Login',
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
