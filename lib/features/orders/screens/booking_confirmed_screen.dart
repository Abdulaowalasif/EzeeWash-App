import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../routes/routes_name.dart';

class BookingConfirmedScreen extends StatefulWidget {
  const BookingConfirmedScreen({super.key});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onAnimationLoaded(Duration duration) {
    _timer = Timer(duration, () {
      if (mounted) {
        context.go(RoutesName.main);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Lottie.asset(
          'assets/animation/confirmed.json',
          repeat: false,
          onLoaded: (comp) => _onAnimationLoaded(comp.duration),
        ),
      ),
    );
  }
}