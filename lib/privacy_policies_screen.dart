import 'package:flutter/material.dart';

class PrivacyPoliciesScreen extends StatelessWidget {
  const PrivacyPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Privacy & Policies",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("🏠 Society Construction Rules"),
            _sectionText(
                "• LDA (Lahore Development Authority):\n"
                    "  - Minimum front setback: 5 ft (Ground Floor)\n"
                    "  - Side setback: 3 ft (one side), 5 ft (other side)\n"
                    "  - Maximum height: 35 ft for 5 Marla house\n"
                    "  - Porch limited to 1 car only (not used as room)\n\n"
                    "• DHA (Defence Housing Authority):\n"
                    "  - Front lawn mandatory: 10 ft minimum\n"
                    "  - Boundary wall height: 7 ft max\n"
                    "  - Basement allowed with approved drawings\n"
                    "  - No commercial activity in residential plots\n\n"
                    "• Bahria Town:\n"
                    "  - Front setback: 5–7 ft\n"
                    "  - Rear setback: 3–5 ft\n"
                    "  - Approval from Bahria Engineering Dept required before start\n"
                    "  - No structure beyond approved map allowed\n"
            ),

            const SizedBox(height: 20),
            _sectionTitle("🔒 User Privacy & Data Policy"),
            _sectionText(
                "We value your privacy. Your personal information, including name, email, and contact details, is securely stored and never shared with third parties without consent. "
                    "Location access (if enabled) is used only to provide construction site mapping and nearby labor services.\n\n"
                    "Users may request data deletion anytime from the app settings."
            ),

            const SizedBox(height: 20),
            _sectionTitle("👷 Safety & Labor Compliance"),
            _sectionText(
                "• All laborers listed on the platform must follow safety protocols such as helmet and boot usage.\n"
                    "• Users hiring workers must ensure site safety measures (first aid, safety gear, etc.).\n"
                    "• The app does not hold liability for on-site accidents but encourages safe practices.\n"
                    "• Laborers should be paid fair wages as per local labor laws."
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text("Back to Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.deepOrange,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}
