// Import required packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:io';

class ContractorMode extends StatefulWidget {
  const ContractorMode({Key? key}) : super(key: key);

  @override
  _ContractorModeState createState() => _ContractorModeState();
}

class _ContractorModeState extends State<ContractorMode> {
  String? selectedSkill;
  String? selectedLocation;
  TextEditingController messageController = TextEditingController();
  File? selectedImage;

  List<Map<String, dynamic>> allContractors = [
    {
      'name': 'Ali Builders',
      'fullName': 'Ali Khan',
      'email': 'ali@example.com',
      'location': 'Lahore',
      'industryExperience': '10 years',
      'laborSkills': ['Electrician', 'Plumber'],
      'isActive': true,
      'rating': 4.5,
      'labors': [
        {'name': 'Noman', 'skill': 'Electrician', 'city': 'Lahore', 'experience': '5 years'},
        {'name': 'Zeeshan', 'skill': 'Plumber', 'city': 'Lahore', 'experience': '3 years'},
      ],
    },
    {
      'name': 'Malik Traders',
      'fullName': 'Malik Hussnain',
      'email': 'malik@gmail.com',
      'location': 'Jhang',
      'industryExperience': '3 years',
      'laborSkills': ['Electrician', 'Carpenter'],
      'isActive': true,
      'rating': 4.5,
      'labors': [
        {'name': 'Saleem', 'skill': 'Electrician', 'city': 'Jhang', 'experience': '2 years'},
        {'name': 'Haider', 'skill': 'Carpenter', 'city': 'Jhang', 'experience': '1 years'},
      ],
    },
    {
      'name': 'Bright Construction',
      'fullName': 'Bilal Ahmed',
      'email': 'bilal@example.com',
      'location': 'Karachi',
      'industryExperience': '6 years',
      'laborSkills': ['Painter', 'Carpenter'],
      'isActive': true,
      'rating': 4.2,
      'labors': [
        {'name': 'Faraz', 'skill': 'Painter', 'city': 'Karachi', 'experience': '4 years'},
        {'name': 'Imran', 'skill': 'Carpenter', 'city': 'Karachi', 'experience': '6 years'},
      ],
    },
  ];

  List<Map<String, dynamic>> filteredContractors = [];

  @override
  void initState() {
    super.initState();
    filteredContractors = allContractors;
  }

  void filterContractors() {
    setState(() {
      filteredContractors = allContractors.where((contractor) {
        final matchSkill = selectedSkill == null || selectedSkill == 'All' || contractor['laborSkills'].contains(selectedSkill);
        final matchLocation = selectedLocation == null || selectedLocation == 'All' || contractor['location'] == selectedLocation;
        return matchSkill && matchLocation;
      }).toList();
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> saveMessageToFirebase(String contractorName, String message, File? file) async {
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'contractor': contractorName,
        'message': message,
        'timestamp': Timestamp.now(),
        'file': file != null ? file.path : null
      });
      showError("Message sent successfully!");
      messageController.clear();
      selectedImage = null;
    } catch (e) {
      showError("Message not sent. Please check your connection and try again.");
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildDropdown('Skill', ['All', 'Electrician', 'Plumber', 'Painter', 'Carpenter'], selectedSkill, (val) {
                      selectedSkill = val!;
                      filterContractors();
                    })),
                    SizedBox(width: 10),
                    Expanded(child: _buildDropdown('Location', ['All', 'Lahore', 'Karachi', 'Jhang'], selectedLocation, (val) {
                      selectedLocation = val!;
                      filterContractors();
                    })),
                  ],
                ),
              ),
              Expanded(
                child: filteredContractors.isEmpty
                    ? Center(
                  child: Text("No contractor found, try again later.",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Roboto')),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredContractors.length,
                  itemBuilder: (context, index) => _buildContractorCard(filteredContractors[index]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      dropdownColor: Colors.grey[900],
      isExpanded: true,
      value: value,
      hint: Text("Select $label", style: TextStyle(color: Colors.white70)),
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
      ))
          .toList(),
    );
  }

  Widget _buildContractorCard(Map<String, dynamic> contractor) {
    return GestureDetector(
      onTap: () {
        if (!contractor['isActive']) {
          showError("This contractor is currently unavailable.");
        } else {
          _showContractorDetails(contractor);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contractor['name'], style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Skills: ${contractor['laborSkills'].join(', ')}", style: TextStyle(color: Colors.white70)),
                Text("Location: ${contractor['location']}", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContractorDetails(Map<String, dynamic> contractor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('contractor', isEqualTo: contractor['name'])
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Name: ${contractor['fullName']}", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text("Email: ${contractor['email']}", style: TextStyle(color: Colors.white)),
                  Text("Experience: ${contractor['industryExperience']}", style: TextStyle(color: Colors.white)),
                  Text("Rating: ${contractor['rating']}", style: TextStyle(color: Colors.white)),
                  SizedBox(height: 10),
                  Text("Available Labors:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ...contractor['labors'].map<Widget>((labor) => ListTile(
                    title: Text(labor['name'], style: TextStyle(color: Colors.white)),
                    subtitle: Text("${labor['skill']} • ${labor['city']} • ${labor['experience']}", style: TextStyle(color: Colors.white70)),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LaborDetailScreen(labor: labor)));
                    },
                  )),
                  Divider(color: Colors.white24),
                  if (snapshot.hasData)
                    ...snapshot.data!.docs.map((doc) => ListTile(
                      title: Text(doc['message'], style: TextStyle(color: Colors.white)),
                      subtitle: Text(doc['timestamp'].toDate().toString(), style: TextStyle(color: Colors.white54)),
                      trailing: doc['file'] != null ? Icon(Icons.attach_file, color: Colors.white) : null,
                    )),
                  SizedBox(height: 10),
                  TextField(
                    controller: messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter your message...",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: Icon(Icons.attach_file),
                        label: Text("Attach File"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => saveMessageToFirebase(contractor['name'], messageController.text.trim(), selectedImage),
                          icon: Icon(Icons.send),
                          label: Text("Send Message"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LaborDetailScreen extends StatelessWidget {
  final Map<String, dynamic> labor;
  const LaborDetailScreen({super.key, required this.labor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Labor Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${labor['name']}", style: TextStyle(color: Colors.white, fontSize: 18)),
            Text("Skill: ${labor['skill']}", style: TextStyle(color: Colors.white70)),
            Text("City: ${labor['city']}", style: TextStyle(color: Colors.white70)),
            Text("Experience: ${labor['experience']}", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}