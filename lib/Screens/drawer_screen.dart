import 'package:baatcheet_app/Screens/chatscreen_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 30.h,
          ),
          ListTile(
            leading: Icon(Icons.recent_actors),
            title: Text('Recent Chat History'),
            onTap: () {
              Get.to(ChatListScreen()); 
            },
          )
        ],
      ),
    );
  }
}
