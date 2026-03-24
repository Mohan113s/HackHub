import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/wrapper.dart';

class SplashGifScreen extends StatefulWidget {
  const SplashGifScreen({super.key});

  @override
  State<SplashGifScreen> createState() => _SplashGifScreenState();
}

class _SplashGifScreenState extends State<SplashGifScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Wrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/gif.gif',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}