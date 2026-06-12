import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';
import 'Help page.dart';
import 'package:smart_constuction_hub/splash_screen.dart';
//import 'package:google_maps_webservice/places.dart';

class LabourHiring extends StatefulWidget {
  const LabourHiring({Key? key}) : super(key: key);

  @override
  _LabourHiringState createState() => _LabourHiringState();
}

class _LabourHiringState extends State<LabourHiring> {


  List<dynamic> locationSuggestions = [];


  String? selectedSkill = 'All';
  String? selectedLocation = null;
  TextEditingController messageController = TextEditingController();
  File? selectedImage;
  // late GoogleMapsPlaces places;

  double? userLat;
  double? userLng;

  List<Map<String, dynamic>> filteredLabors = []; // filtered list
  List<Map<String, dynamic>> allLabors = [];      // full list from Firestore


  final TextEditingController skillController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final DatabaseReference laborsRef =
  FirebaseDatabase.instance.ref('Labors');

  @override
  void initState() {
    super.initState();
    //places = GoogleMapsPlaces(apiKey: "AIzaSyAZbBWxm0pG6WWByEiswHDxZhZxM9xk-SE");
    initLabors();
    filterNearbyLabors();
  }



  Future<void> initLabors() async {
    await getUserLocation();       // 1. Get user location first
    await fetchLabors(); // 2. Then fetch labors
  }

  Future<void> fetchLocationSuggestions(String input) async {
    if (input.length < 3) {
      setState(() => locationSuggestions = []);
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key= AIzaSyAZbBWxm0pG6WWByEiswHDxZhZxM9xk-SE";

    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);

    setState(() {
      locationSuggestions = data["predictions"];
    });
  }

////////////

  Future<void> getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLat = position.latitude;
        userLng = position.longitude;
      });

      // Optionally filter labors if you need to
      // filterLabors();

    } catch (e) {
      debugPrint("Location permission denied or error: $e");

      // Fallback: set default location or skip filtering
      setState(() {
        userLat = 0.0; // or some default
        userLng = 0.0;
      });

      // Optionally show a message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location access denied. Showing all labors without filtering.",
          ),
        ),
      );

      // Still fetch & show the labor list
      // filterLabors(); // if needed
    }
  }


  void filterLabors() {
    filteredLabors = allLabors.where((labor) {
      final skillMatch =
          selectedSkill == 'All' ||
              labor['Skills']
                  .toString()
                  .toLowerCase()
                  .contains(selectedSkill!.toLowerCase());


      final locationMatch = selectedLocation == null ||
          selectedLocation!.isEmpty ||
          labor['Location']
              .toString()
              .toLowerCase()
              .contains(selectedLocation!.toLowerCase());

      return skillMatch && locationMatch;
    }).toList();

    setState(() {});
  }

  void filterLaborsByDistance({double maxKm = 10}) {
    if (userLat == null || userLng == null) return;

    filteredLabors = allLabors.where((labor) {
      final laborLat = labor['Lat'] ?? 0;
      final laborLng = labor['Lng'] ?? 0;
      final distance = Geolocator.distanceBetween(
        userLat!,
        userLng!,
        laborLat,
        laborLng,
      ) / 1000; // convert to km
      return distance <= maxKm;
    }).toList();

    setState(() {});
  }














  Future<void> fetchLabors() async {
    laborsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        print("NO LABORS FOUND IN DB");
        return;
      }

      final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;

      setState(() {
        allLabors = map.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        filteredLabors = allLabors; // 👈 FORCE SHOW ALL
      });

      print("LABORS LOADED: ${allLabors.length}");
    });
  }

  Future<void> filterNearbyLabors({double maxKm = 10}) async {
    // 1️⃣ Get user location
    Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double userLat = userPosition.latitude;
    double userLng = userPosition.longitude;

    // 2️⃣ Get labors from Firebase
    final laborsSnapshot = await FirebaseDatabase.instance
        .ref('Labors')
        .once();

    final data = laborsSnapshot.snapshot.value;
    if (data == null) {
      print("No labors found");
      return;
    }

    final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
    final allLabors = map.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // 3️⃣ Filter labors by distance
    final nearbyLabors = allLabors.where((labor) {
      double laborLat = labor['Lat'] ?? 0;
      double laborLng = labor['Lng'] ?? 0;
      double distanceKm = Geolocator.distanceBetween(
          userLat, userLng, laborLat, laborLng) / 1000;
      return distanceKm <= maxKm; // within 10 km
    }).toList();

    // 4️⃣ Sort nearest first
    nearbyLabors.sort((a, b) {
      double distA = Geolocator.distanceBetween(
          userLat, userLng, a['Lat'], a['Lng']);
      double distB = Geolocator.distanceBetween(
          userLat, userLng, b['Lat'], b['Lng']);
      return distA.compareTo(distB);
    });

    // 5️⃣ Update your state
    setState(() {
      filteredLabors = nearbyLabors;
    });
  }





  Future<void> fetchLaborsAndCalculateDistance() async {
    Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    laborsRef.once().then((event) {
      final data = event.snapshot.value;
      if (data != null) {
        final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
        final laborsList = map.values
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        for (var labor in laborsList) {
          double distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            labor['Lat'] ?? 0,
            labor['Lng'] ?? 0,
          );
          print('${labor['Name']} is ${distance / 1000} km away');
        }
      }
    });
  }


  Future<void> sendHireRequest(Map<String, dynamic> labor, String message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ref = FirebaseDatabase.instance.ref('hire_requests').push();
      await ref.set({
        'laborName': labor['Name'],
        'skill': labor['Skills'],
        'city': labor['Location'],
        'message': message,
        'status': 'pending',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userEmail': user?.email ?? 'anonymous@guest.com'
      });
      showMessage("Request sent to ${labor['Name']}", color: Colors.green);
      messageController.clear();
      selectedImage = null;
    } catch (e) {
      showMessage("Failed to send request. Try again later.");
    }
  }


  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref('hire_requests/$requestId')
          .update({'status': status});
      showMessage("Request marked as $status", color: Colors.deepPurple);
    } catch (e) {
      showMessage("Failed to update status.");
    }
  }

  void showMessage(String message, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    skillController.dispose();
    locationController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color(0xFF302F2F),
      appBar: AppBar(
        title: Text("Labour Hiring",
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700
          ),),
        backgroundColor: const Color(0xFFFFBC3A),

        actions: [
          IconButton(
            icon: const Icon(Icons.home,
                size: 25,
                color: const Color(0xFF302F2F)
            ),
            tooltip: "Home",
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SplashScreen(nextPage: HomePage()),
                  ) );
            },
          ),
          SizedBox(
              width:12
          ),
          IconButton(
            icon: const Icon(Icons.mail,
                size: 25,
                color: const Color(0xFF302F2F)
            ),
            tooltip: "Email",
            onPressed: () async {
              final Uri emailUri =
              Uri(scheme: 'mailto', path: '26116@students.riphah.edu.pk');
              await launchUrl(emailUri);
            },
          ),
          SizedBox(
              width:12
          ),
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
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56, // 👈 same as TextField
                        child: InputDecorator(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white12,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSkill,
                              isExpanded: true,
                              dropdownColor: Colors.grey[900],
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              items: ['All', 'Electrician', 'Plumber', 'Painter', 'Carpenter']
                                  .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedSkill = val;
                                  skillController.text = val == 'All' ? '' : val!;
                                });
                                filterLabors();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Enter location (e.g. Lahore)",
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white12,
                        ),
                        onChanged: (value) {

                          fetchLocationSuggestions(value);
                        },
                      ),
                    ),
                  ],
                ),

                if (locationSuggestions.isNotEmpty)
                  Container(
                    color: Colors.grey[900],
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locationSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = locationSuggestions[index];
                        return ListTile(
                            title: Text(
                              suggestion['description'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () async {
                              final suggestion = locationSuggestions[index];
                              locationController.text = suggestion['description'];
                              locationSuggestions = [];

                              selectedLocation = suggestion['description'];

                              // await getLatLngFromPlaceId(suggestion['place_id']); // get lat/lng and filter
                            }
                        );
                      },
                    ),
                  ),


              ],
            ),
          ),

          Expanded(
            child: filteredLabors.isEmpty
                ? const Center(
                child:
                Text("No labor found.", style: TextStyle(color: Colors.white)))
                : ListView.builder(
              itemCount: filteredLabors.length,
              itemBuilder: (context, index) =>
                  _buildLaborCard(filteredLabors[index]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: Colors.white,
      hint: Text("Select $label", style: TextStyle(color: Colors.white70)),
      items: items
          .map((item) =>
          DropdownMenuItem(
            value: item,
            child: Text(item),
          ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLaborCard(Map<String, dynamic> labor) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        // ✅ Updated title to show phone number before dropdown arrow
        title: Row(
          children: [
            Expanded(
              child: Text(
                labor['Name'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                launchUrl(Uri.parse('tel:${labor['Phone'].toString()}'));
              },
              child: Row(
                children: [
                  const Icon(Icons.phone,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    labor['Phone'].toString(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${labor['Skills']} • ${labor['Location']} • ⭐ ${labor['Rating']}",
          style: const TextStyle(color: Colors.white70),
        ),
        children: [
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('hire_requests')
                .orderByChild('laborName')
                .equalTo(labor['Name'])
                .onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.redAccent)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No requests yet.",
                      style: TextStyle(color: Colors.white54)),
                );
              }

              final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              final requests = data.entries
                  .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
                  .toList();

              return Column(
                children: requests.map((req) {
                  return ListTile(
                    title: Text(req['userEmail'] ?? 'Unknown User',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        "${req['message']}\nStatus: ${req['status']}",
                        style: const TextStyle(color: Colors.white70)),
                    trailing: req['status'] == 'pending'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                          const Icon(Icons.check, color: Colors.greenAccent),
                          onPressed: () =>
                              updateRequestStatus(req['id'], 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () =>
                              updateRequestStatus(req['id'], 'rejected'),
                        ),
                      ],
                    )
                        : Icon(
                      req['status'] == 'accepted'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: req['status'] == 'accepted' ? Colors.green : Colors.red,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Send a hiring request:",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter your message...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () =>
                      sendHireRequest(labor, messageController.text.trim()),
                  icon: const Icon(Icons.send),
                  label: const Text("Send Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}