import 'dart:io';

import 'package:baatcheet_app/Authenticate/signin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../helper/ui_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isSigningUp = false;
  bool _obscureText = true;
  bool _obscureText1 = true;
  final bool _isLoading = false;
  File? _profileImage;

  void _selectProfileImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  void _selectProfileCameraImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) {
      return null;
    }

    final storageRef =
        FirebaseStorage.instance.ref().child('profile_images/$userId.jpg');
    final uploadTask = storageRef.putFile(_profileImage!);
    final snapshot = await uploadTask.whenComplete(() {});
    final imageUrl = await snapshot.ref.getDownloadURL();
    return imageUrl;
  }

  void signUp(context) async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      if (_passwordController.text == _confirmPasswordController.text) {
        try {
          setState(() {
            _isSigningUp = true;
          });

          // Create user in Firebase Authentication
          UserCredential? userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          // Upload profile image and get the image URL
          final imageUrl = await _uploadProfileImage(userCredential.user!.uid);

          // Save additional user data to Firebase Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text,
            'email': _emailController.text,
            'profileImageUrl': imageUrl ?? '',
            "status": "unavailable",
            "uid": FirebaseAuth.instance.currentUser!.uid,
          });

          setState(() {
            _isSigningUp = false;
          });

          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully!'),
            ),
          );

          // Navigate to the sign-in screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            setState(() {
              UIHelper.showAlertDialog(
                context,
                "Error Occurred!",
                "Email already in use. Please sign in instead.",
              );
              _isSigningUp = false;
            });
          } else {
            print("123455${e.toString()}");
            setState(() {
              UIHelper.showAlertDialog(
                context,
                "Error Occurred!",
                "An error occurred. Please try again later.",
              );
              _isSigningUp = false;
            });
          }
        } catch (e) {
          print("123455${e.toString()}");
          setState(() {
            UIHelper.showAlertDialog(
              context,
              "Error Occurred!",
              "An error occurred. Please try again later.",
            );
            _isSigningUp = false;
          });
        }
      } else {
        setState(() {
          UIHelper.showAlertDialog(
            context,
            "Error Occurred!",
            "Passwords do not match!",
          );
        });
      }
    }
  }

  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // void signUpWithGoogle(context) async {
  //   try {
  //     setState(() {
  //       _isSigningUp = true;
  //     });

  //     // Trigger the Google sign-in flow
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser!.authentication;

  //     // Create a new credential using the Google sign-in token
  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Sign in with the credential
  //     final UserCredential userCredential =
  //         await _auth.signInWithCredential(credential);

  //     // Get the user details
  //     final User? user = userCredential.user;
  //     final String? name = user!.displayName;
  //     final String? email = user.email;
  //     final String? profileImageUrl = user.photoURL;

  //     // Save additional user data to Firebase Firestore
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'name': name,
  //       'email': email,
  //       'profileImageUrl': profileImageUrl ?? '',
  //     });

  //     setState(() {
  //       _isSigningUp = false;
  //     });

  //     // Show snackbar
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Account created successfully!'),
  //       ),
  //     );

  //     // Navigate to the sign-in screen
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => SignInScreen()),
  //     );
  //   } catch (e) {
  //     print('Sign-up with Google failed: $e');
  //     setState(() {
  //       _isSigningUp = false;
  //     });
  //     // Show an error dialog
  //     UIHelper.showAlertDialog(
  //       context,
  //       "Error Occurred!",
  //       "An error occurred while signing up with Google. Please try again later.",
  //     );
  //   }
  // }

  // Function to check internet connectivity
  Future<bool> checkInternetConnectivity() async {
    return await InternetConnectionChecker().hasConnection;
  }

// Function to display the "No Internet" dialog box
  void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet!'),
          content: Text('Please connect to your internet.'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 36, 120, 109)),
              child: Text('OK'),
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
    return ScreenUtilInit(
      useInheritedMediaQuery: true,
      builder: (context, child) => Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Image.asset('assets/images/Back (1).png'),
            )),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Center(
                          child: Text(
                        'Sign up with Email',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      SizedBox(
                        height: 15.h,
                      ),
                      Center(
                          child: Text(
                        textAlign: TextAlign.center,
                        'Get chatting with friends and family today by\n signing up for our chat app!',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      )),
                      SizedBox(
                        height: 20.h,
                      ),
                      GestureDetector(
                          // onTap: _selectProfileImage ,
                          onTap: () {
                            Get.defaultDialog(
                                title: 'Choose a profile image from',
                                content: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        iconSize: 40,
                                        onPressed: _selectProfileImage,
                                        icon: Icon(Icons.photo)),
                                    SizedBox(width: 15.w),
                                    IconButton(
                                        iconSize: 40,
                                        onPressed: _selectProfileCameraImage,
                                        icon: Icon(Icons.camera_alt)),
                                  ],
                                ),
                                confirm: TextButton(
                                    style: TextButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 36, 120, 109)),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Ok',
                                      style: TextStyle(color: Colors.white),
                                    )));
                          },
                          child: Center(
                              child: Container(
                            height: 120.h,
                            width: 120.h,
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: Color.fromARGB(255, 36, 120, 109),
                              ),
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                            child: Container(
                              height: 120.h,
                              width: 120.h,
                              decoration: _profileImage != null
                                  ? BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.r),
                                      image: DecorationImage(
                                          image: FileImage(_profileImage!),
                                          fit: BoxFit.cover),
                                    )
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.camera_alt,
                                      size: 50.0,
                                      color: Color.fromARGB(255, 36, 120, 109),
                                    )
                                  : null,
                            ),
                          ))),
                      TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 36, 120, 109),
                              fontWeight: FontWeight.w500),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 205, 209, 208)),
                          ),
                        ),
                        cursorColor: Color.fromARGB(255, 36, 120, 109),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Your Email',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 36, 120, 109),
                              fontWeight: FontWeight.w500),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 205, 209, 208)),
                          ),
                        ),
                        cursorColor: Color.fromARGB(255, 36, 120, 109),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your email.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 36, 120, 109),
                              fontWeight: FontWeight.w500),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 205, 209, 208)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Color.fromARGB(255, 36, 120, 109)),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        cursorColor: Color.fromARGB(255, 36, 120, 109),
                        obscureText: _obscureText,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          } else if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                            return 'Password must contain at least one letter';
                          } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Password must contain at least one number';
                          }
                          return null; // Return null if the validation passes
                        },
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(255, 36, 120, 109),
                              fontWeight: FontWeight.w500),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 205, 209, 208)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText1
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color.fromARGB(255, 36, 120, 109),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText1 = !_obscureText1;
                              });
                            },
                          ),
                        ),
                        cursorColor: Color.fromARGB(255, 36, 120, 109),
                        obscureText: _obscureText1,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          return null;
                        },
                      ),
                      // SizedBox(
                      //   height: 10.h,
                      // ),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //         flex: 3,
                      //         child: Divider(
                      //           thickness: 1,
                      //         )),
                      //     SizedBox(
                      //       width: 30.w,
                      //     ),
                      //     Expanded(
                      //       flex: 1,
                      //       child: Text(
                      //         'Or',
                      //         style: TextStyle(
                      //             fontSize: 18.sp,
                      //             color: Color.fromARGB(255, 215, 139, 25)),
                      //       ),
                      //     ),
                      //     Expanded(
                      //         flex: 3,
                      //         child: Divider(
                      //           thickness: 1,
                      //         )),
                      //   ],
                      // ),

                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Color.fromARGB(255, 215, 139, 25),
                      //   ),
                      //   onPressed: () async {
                      //     bool isConnected = await checkInternetConnectivity();
                      //     if (isConnected) {
                      //       _isSigningUp ? null : signUpWithGoogle(context);
                      //     } else {
                      //       showNoInternetDialog(context);
                      //     }
                      //   },
                      //   child: Row(
                      //     mainAxisSize: MainAxisSize.min,
                      //     children: [
                      //       SizedBox(width: 8),
                      //       Text('Sign Up with   '),
                      //       Container(
                      //         height: 25.h,
                      //         width: 25.h,
                      //         decoration: BoxDecoration(
                      //             image: DecorationImage(
                      //                 image: AssetImage(
                      //                     'assets/images/google (1).png'))),
                      //       )
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 15, right: 15),
              height: 48.h,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r)),
                    backgroundColor: Color.fromARGB(255, 36, 120, 109)),
                onPressed: () async {
                  bool isConnected = await checkInternetConnectivity();
                  if (isConnected) {
                    _isSigningUp ? null : signUp(context);
                  } else {
                    showNoInternetDialog(context);
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text('Create an account',
                        style: TextStyle(fontSize: 16.sp)),
              ),
            ),
            SizedBox(
              height: 5.h,
            )
          ],
        ),
      ),
    );
  }
}
