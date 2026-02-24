import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          spacing: 10,
          children: [
            Icon(Icons.smart_toy_outlined),
            Text("Bubble Bot", style: GoogleFonts.alexandria()),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animation/bot.json'),
            Text("Coming soon...", style: GoogleFonts.alexandria(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
