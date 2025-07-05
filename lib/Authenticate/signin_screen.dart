import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/home_screen.dart';
import '../helper/ui_helper.dart';
import 'forget_password.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool isSelected = false;

  void signIn(context) async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true; // Start showing the progress indicator
      });
      try {
        final authResult =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (authResult.user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get()
              .then(
                  (value) => authResult.user!.updateDisplayName(value['name']));
          // FocusScope.of(context).unfocus();
          // Navigate to the home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          // Show alert dialog if sign-in is unsuccessful
          UIHelper.showAlertDialog(context, "Error Occurred!",
              "Invalid email or password. Please try again.");
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          // Show alert dialog for wrong password
          UIHelper.showAlertDialog(
              context, "Error Occurred!", "Wrong password. Please try again!");
        } else {
          // Show alert dialog for other sign-in errors
          UIHelper.showAlertDialog(
              context, "Error Occurred!", "Please enter valid email!");
        }
      } catch (e) {
        // Handle other errors
        print('Sign-in Error: $e');
      } finally {
        setState(() {
          _isLoading = false; // Stop showing the progress indicator
        });
      }
    }
  }

  bool? isChecked = false;
//firts make state ful class in second class declare this two functions
  void handleRememberMe(bool? value) {
    isChecked = value;
    SharedPreferences.getInstance().then(
      (prefs) {
        prefs.setBool("remember_me", value!);
        prefs.setString('email', _emailController.text);
        prefs.setString('password', _passwordController.text);
      },
    );
    setState(() {
      isChecked = value;
    });
  }

  void _loadUserEmailPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email") ?? "";
      var password = prefs.getString("password") ?? "";
      var rememberMe = prefs.getBool("remember_me") ?? false;
      print(rememberMe);
      print(email);
      print(password);
      if (rememberMe) {
        setState(() {
          isChecked = true;
        });
        _emailController.text = email;
        _passwordController.text = password ?? "";
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _loadUserEmailPassword();
    super.initState();
  }
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
                padding: EdgeInsets.only(left: 15, right: 15),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Center(
                          child: Text(
                        'Log in to Baat Cheet',
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
                        'Welcom back! Sign in using your google\n account or email to continue us',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      )),
                      SizedBox(
                        height: 20.h,
                      ),
                      Container(
                        height: 50.h,
                        width: 50.h,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/light google logo.png'))),
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      Image.asset('assets/images/Or.png'),
                      SizedBox(
                        height: 20.h,
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
                        textInputAction: TextInputAction.done,
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
                            return 'Please enter your password.';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          const Text("Remember Me",
                              style: TextStyle(
                                color: Colors.black,
                              )),
                          Checkbox(
                            activeColor: Colors.blue,
                            value: isChecked,
                            onChanged: handleRememberMe,
                          ),
                        ],
                      ),
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
                    _isLoading ? null : signIn(context);
                  } else {
                    showNoInternetDialog(context);
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        'Log in',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Color.fromARGB(255, 36, 120, 109)),
                onPressed: () {
                  Get.to(ForgotPasswordScreen());
                },
                child: Text('Forgot Password?'))
          ],
        ),
      ),
    );
  }
}
