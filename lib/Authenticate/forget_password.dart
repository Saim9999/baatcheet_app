import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _resetPassword(context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text,
        );

        // Show success message or navigate to a success screen
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Password Reset'),
            content: Text(
                'An email with password reset instructions has been sent to your email address.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to sign-in screen or any other desired screen
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  backgroundColor: Color.fromARGB(255, 215, 139, 25)),
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
                        'Forgot your password?',
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
                        'Please enter the email address you\'d like your\n password reset information sent to',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      )),
                      SizedBox(
                        height: 20.h,
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Your Reset Email',
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
                    _isLoading ? null : _resetPassword(context);
                  } else {
                    showNoInternetDialog(context);
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
