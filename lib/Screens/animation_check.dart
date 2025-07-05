// import 'package:flutter/material.dart';
// import 'package:flutter_animated_icons/icons8.dart';
// import 'package:lottie/lottie.dart';

// class Checkanimation extends StatefulWidget {
//   const Checkanimation({super.key});

//   @override
//   State<Checkanimation> createState() => _CheckanimationState();
// }

// class _CheckanimationState extends State<Checkanimation>
//     with TickerProviderStateMixin {
//   late AnimationController _sendController;

//   @override
//   void initState() {
//     super.initState();

//     _sendController =
//         AnimationController(vsync: this, duration: const Duration(seconds: 1));
//   }

//   @override
//   void dispose() {
//     _sendController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView(
//         children: [
//           IconButton(
//             splashRadius: 50,
//             iconSize: 100,
//             onPressed: () {
//               _sendController.reset();
//               _sendController.forward();
//             },
//             icon: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Lottie.asset('assets/animations/send_animation.json',
//                   controller: _sendController),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
