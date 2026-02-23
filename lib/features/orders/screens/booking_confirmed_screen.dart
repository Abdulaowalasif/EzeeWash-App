import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Lottie.asset(
          repeat: false,
          'assets/animation/confirmed.json',
        ),
      ),
    );
  }
}
