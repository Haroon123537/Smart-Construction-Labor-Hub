import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'Help page.dart';
import 'package:smart_constuction_hub/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hiring_services.dart';

class LabourHiringPage extends StatefulWidget {
  final String selectedCity;

  const LabourHiringPage({
    super.key,
    required this.selectedCity,
  });


  @override
  _LabourHiringPageState createState() => _LabourHiringPageState();
}

class _LabourHiringPageState extends State<LabourHiringPage>
    with TickerProviderStateMixin {
  final TextEditingController _areaController = TextEditingController();
  List<Map<dynamic, dynamic>> displayedLabors = [];
  List<Map<dynamic, dynamic>> allLabors = [];
  double? userLat;
  double? userLng;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late AnimationController _gpsController;
  late AnimationController _buttonController;
  late Animation<double> _rotationAnimation;
  bool isLoading = false;
  bool _hasLocationPermission = false;
  String selectedSkill = 'All'; // default selected skill
  final List<String> skillsList = [
    'All', 'Electrician', 'Plumber', 'Carpenter', 'Mason', 'Painter'
  ];


  @override
  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // rotates for 0.5s
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_buttonController);


    _fetchLabors();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());


    _gpsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _gpsController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _gpsController.repeat(); // keep spinning until stopped manually
      }
    });


    _checkLocationPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _gpsController.dispose();
    _areaController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _sendHireRequest(Map labor) async {
    try {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage("You must be logged in to hire a labor.");
        return;
      }

      final userEmail = user.email ?? '';
      final userId = user.uid;

      // Start button rotation animation
      _buttonController.forward();
      await Future.delayed(const Duration(milliseconds: 500));

      // Prepare labor data safely
      final laborId = labor['id']?.toString() ?? '';
      final laborName = labor['Name']?.toString() ?? '';
      final skill = labor['Skills']?.toString() ?? '';
      final city = widget.selectedCity ?? '';

      // Push request to Firebase Realtime Database
      DatabaseReference ref = FirebaseDatabase.instance.ref("hiring_requests");
      DatabaseReference newRequestRef = ref.push();

      await newRequestRef.set({
        'laborId': laborId,
        'laborName': laborName,
        'skill': skill,
        'city': city,
        'status': 'pending',
        'userEmail': userEmail,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });


      await HiringService().checkAndProcessHiringRequest(
        requestId: newRequestRef.key!,
        laborId: laborId,
        skill: skill,
        userId: userId,
      );

      _showMessage("Hire request sent successfully!");
    } catch (e) {
      _showMessage("Error sending request: $e");
    } finally {
      _buttonController.reset(); // Reset rotation animation
    }
  }



  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage("Please allow location access to find nearby labors");
      _hasLocationPermission = false;
    } else {
      _hasLocationPermission = true;
    }
  }


  // Fetch all labors from Firebase Realtime Database
  void _fetchLabors() {
    FirebaseDatabase.instance.ref('Labors').onValue.listen((event) {
      final Map<dynamic, dynamic>? data =
      event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return;

      allLabors.clear();

      data.forEach((key, value) {
        // ✅ Attach Firebase key as labor ID
        value['id'] = key;

        // ✅ City filter (your existing logic)
        if (value['city']
            .toString()
            .toLowerCase()
            .trim() ==
            widget.selectedCity.toLowerCase().trim()) {
          allLabors.add(Map<dynamic, dynamic>.from(value));
        }
      });

      setState(() {
        displayedLabors = allLabors;
      });
    });
  }



  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    double dLat = _deg2rad(lat2 - lat1);
    double dLng = _deg2rad(lng2 - lng1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;


  Future<void> _searchNearbyLabors() async {
    print("🔍 Search started");

    String area = _areaController.text.trim();

    // 1️⃣ Typed address search
    if (area.isNotEmpty) {
      try {
        print("📌 Geocoding address: $area");
        List<Location> locations = await locationFromAddress(area);

        if (locations.isEmpty) {
          print("❌ No coordinates found for address");
          _disableSearchBar();
          _showMessage("Could not find your address. Please use GPS.");
          return;
        }


        userLat = locations.first.latitude;
        userLng = locations.first.longitude;

        print("Address resolved: $userLat , $userLng");


        _filterLaborsByDistance(maxDistanceKm: 5);

        return;
      } catch (e) {
        print("❌ Geocoding error: $e");
        _disableSearchBar();
        _showMessage("Could not resolve address. Please use GPS.");
        return;
      }
    }


    await _getCurrentLocation();
  }



  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }


  void _filterLaborsByDistance({double maxDistanceKm = 10}) {
    if (userLat == null || userLng == null) return;

    final nearby = allLabors.where((labor) {
      if (labor['Availability'] != true) return false;

      final lat = (labor['Lat'] as num?)?.toDouble();
      final lng = (labor['Lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return false;

      final distance = _calculateDistance(userLat!, userLng!, lat, lng);
      if (distance > maxDistanceKm) return false;


      if (selectedSkill != 'All' && labor['Skills'] != selectedSkill) return false;

      return true;
    }).toList();

    setState(() {
      displayedLabors = nearby;
    });


    if (displayedLabors.isEmpty) {
      _showMessage(
          "No labors found within $maxDistanceKm km of this location. Try another area or adjust your skill filter.");
    } else {
      _showMessage("${displayedLabors.length} labors found within $maxDistanceKm km.");
    }
  }


  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage("Please turn ON location services.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage("Location permission is required.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userLat = position.latitude;
      userLng = position.longitude;

      // Use the same 10 km filter for GPS search
      _filterLaborsByDistance(maxDistanceKm: 5);

    } catch (e) {
      print("❌ Error getting current location: $e");
      _showMessage("Could not get your location. Please try again.");
    }
  }


  void _disableSearchBar() {

    _areaController.clear();
    print("❌ Search bar disabled, only GPS allowed.");
  }



  void _onGpsPressed() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage("Please allow location access to use GPS");
      return; // stop here until user grants permission
    }

    _gpsController.forward(); // start rotating
    await _getCurrentLocation(); // fetch labors
    _gpsController.stop(); // stop rotating
    _gpsController.reset();
  }





  @override
  Widget build(BuildContext context) {
    final Map<String, String> t = {
      'header': 'Hey there 👋\nFinding skilled labors near you...',
    };
    return Scaffold(
      backgroundColor:  const Color(0xFF302F2F),
      appBar: AppBar(title: const Text('Labour Hiring'),
        backgroundColor: const Color(0xFFFFBC3A),


        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: const Color(0xFF302F2F) ,),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SplashScreen(nextPage: HomePage()),
            ),
          ),
          ),
          SizedBox(
            width: 15,
          ),
          IconButton(
            icon: const Icon(Icons.mail, color: const Color(0xFF302F2F)),
            onPressed: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: '26116@students.riphah.edu.pk',
              );
              await launchUrl(emailUri);
            },
          ),


          const SizedBox(width: 15),

          IconButton(
            icon: const Icon(Icons.help,
                size: 25,
                color: const Color(0xFF302F2F)
            ),
            tooltip: "Help",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>  SplashScreen(nextPage: ChatBot()),
                  ));
            },
          ),
          SizedBox(width: 10,)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Text(
                  t['header']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Colors.white,
                    height: 1.4,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Location input
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextField(
                    controller: _areaController,
                    readOnly: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your location...',
                      hintStyle: const TextStyle(color: Colors.white54),
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
                      suffixIcon: RotationTransition(
                        turns: _gpsController,
                        child: IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.white),
                          onPressed: _hasLocationPermission
                              ? _onGpsPressed
                              : () {
                            _showMessage("Please allow location access first");
                          },
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _searchNearbyLabors(),
                  ),
                ),

                const SizedBox(width: 10),

                // Skill dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF302F2F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSkill,
                    dropdownColor: const Color(0xFF302F2F),
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: skillsList.map((skill) {
                      return DropdownMenuItem(
                        value: skill,
                        child: Text(skill),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSkill = value!;
                        _filterLaborsByDistance(maxDistanceKm: 5); // refresh results
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Updated Labor list
            displayedLabors.isEmpty
                ? const Center(
                child: Text('No labors found', style: TextStyle(color: Colors.white)))
                : Column(
              children: displayedLabors.map((labor) {
                return Container(
                    width: double.infinity,
                    child:Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        // Rating & phone at top-right
                        Positioned(
                          right: 0,
                          top: 0,
                           child:Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "⭐ ${labor['Rating']}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${labor['Phone']}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    // Call Icon
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          final Uri callUri = Uri(scheme: 'tel', path: labor['Phone']);
                                          if (await canLaunchUrl(callUri)) {
                                            await launchUrl(callUri);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.phone,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),


                                    const SizedBox(width: 5),
                                    // SMS Icon
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () async {
                                          final Uri smsUri = Uri(scheme: 'sms', path: labor['Phone']);
                                          if (await canLaunchUrl(smsUri)) {
                                            await launchUrl(smsUri);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Cannot send SMS")),
                                            );
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.message,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ],
                            )

                        ),

                        // Labor details + button at bottom-left
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labor['Name'],
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${labor['Skills']} | ${labor['Experience']} | ${labor['Location']}",
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(height: 12),
                            _HireButton(
                                labor: labor, sendHireRequest: _sendHireRequest),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30), // gap before info text

            // Centered info text at bottom
            Center(
              child: Text(
                "For more queries, tap the mail or help icon",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20), // extra padding at bottom
          ],
        ),
      ),

    );
        }
}

class _HireButton extends StatefulWidget {
  final Map labor;
  final Future<void> Function(Map) sendHireRequest;

  const _HireButton({required this.labor, required this.sendHireRequest});

  @override
  State<_HireButton> createState() => _HireButtonState();
}

class _HireButtonState extends State<_HireButton>
     {

  bool isLoading = false;


  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const SizedBox(
      height: 36,
      width: 36,
      child: CircularProgressIndicator(strokeWidth: 3),
    )
        : ElevatedButton(
      onPressed: () async {
        setState(() => isLoading = true); // hide button

        await widget.sendHireRequest(widget.labor);

        await Future.delayed(const Duration(seconds: 2)); // 2–3 sec delay

        if (mounted) {
          setState(() => isLoading = false); // show button again
        }
      },
      child: const Text("Hire"),
    );
  }

}
