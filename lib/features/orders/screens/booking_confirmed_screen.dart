import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animation/confirmed.json',
        ),
      ),
    );
  }
}
