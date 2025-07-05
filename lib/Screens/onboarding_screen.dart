
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../Authenticate/sign_up_screen.dart';
import '../Authenticate/signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Image.asset('assets/images/onboarding blur image.png'),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: ListView(
              children: [
                Container(
                  height: 70.h,
                  width: 160.w,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Second logo.png'),
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'Connect friends',
                  style: TextStyle(color: Colors.white, fontSize: 68.sp),
                ),
                Text(
                  'easily & quickly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 68.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  'Our chat app is the perfect way to stay',
                  style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                ),
                SizedBox(height: 5.h),
                Text(
                  'connected with friends and family.',
                  style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                ),
                SizedBox(height: 20.h),
                Container(
                  height: 50.h,
                  width: 50.h,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/google logo.png'),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Image.asset('assets/images/Or-uihut.png'),
                SizedBox(height: 20.h),
                InkWell(
                  onTap: () {
                    // Get.to(CreateAccount());
                    // Get.to(SignupScreen());
                    Get.to(() => SignupScreen());
                  },
                  child: Image.asset('assets/images/signup button.png'),
                ),
                SizedBox(height: 15.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Existing account?',
                      style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                    ),
                    TextButton(
                      onPressed: () {
                        // Get.to(SignInScreen());
                        Get.to(() => SignInScreen());
                      },
                      child: Text(
                        'Log in',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
