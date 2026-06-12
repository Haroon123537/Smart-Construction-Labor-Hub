import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextPage;

  const SplashScreen({Key? key, required this.nextPage}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..forward(); // Play once

    _rotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 4));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextPage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.indigo.shade500, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: _rotation.value,
                    child: Image.asset(
                      'assets/logo.jpg',
                      height: 130,
                    ),
                  ),
                  SizedBox(height: 20),
                  Opacity(
                    opacity: _fadeIn.value,
                    child: Text(
                      "Smart Construction Hub",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
