import 'package:flutter/material.dart';
import 'labour_hiring.dart';

class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage>
    with SingleTickerProviderStateMixin{

  final TextEditingController _cityController = TextEditingController();
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup for header sliding from top
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // start above the screen
      end: Offset.zero, // final position
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start animation on page open
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _enterCity() async {
    String city = _cityController.text.trim();

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your city name")),
      );
      return;
    }

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // fake loading

    if (!mounted) return; // safety check

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LabourHiringPage(selectedCity: city),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove backgroundColor, we'll use image
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFBC3A),
        elevation: 8,
      ),
      extendBodyBehindAppBar: true, // allow image behind AppBar
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/City_Background.jpg'), // your image path
                fit: BoxFit.cover, // cover whole page
              ),
            ),
          ),

          // Semi-transparent overlay to darken background for readability
          Container(
            color: Colors.black.withOpacity(0.5),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Header
                  SlideTransition(
                    position: _slideAnimation,
                    child: const Text(
                      "Enter Your City",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // TextField + Button in one row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: TextField(

                          controller: _cityController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'e.g Lahore,Karachi.',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white54),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white),
                            ),

                          ),

                        ),
                      ),

                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading ? null : _enterCity,
                          child: isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                              : const Text(
                            "Enter",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
