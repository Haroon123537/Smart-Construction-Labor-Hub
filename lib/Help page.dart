import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';


class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allQA = [];
  final Map<int, bool> _expandedMap = {};
  String selectedLanguage = "English";

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  final Map<String, Map<String, String>> localizedText = {
    "English": {
      "title": "Help & FAQs",
      "email": "Email",
      "home": "Home",
      "header":
      "Hello! How can we help you?\nBrowse the questions below to get guidance",
    },
    "Urdu": {
      "title": "مدد اور سوالات",
      "email": "ایمیل",
      "home": "ہوم",
      "header":
      "ہیلو! ہم آپ کی کیسے مدد کر سکتے ہیں؟\nرہنمائی کے لیے نیچے دیے گئے سوالات دیکھیں",
    }
  };

  @override
  void initState() {
    super.initState();
    loadAnswers();

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

    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _controller.forward(),
    );
  }

  Future<void> loadAnswers() async {
    final jsonStr =
    await rootBundle.loadString('assets/answering.json');
    final data = json.decode(jsonStr) as List;
    setState(() {
      _allQA = List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = localizedText[selectedLanguage]!;

    final filteredQA = _allQA.where((item) {
      if (item.isEmpty) return false;
      final isUrdu =
      RegExp(r'[\u0600-\u06FF]').hasMatch(item['question']);
      return selectedLanguage == "Urdu" ? isUrdu : !isUrdu;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFBC3A),

        title: Text(
          t["title"]!,
          style: const TextStyle(
              color: const Color(0xFF302F2F), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: const Color(0xFF302F2F) ,),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
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
          SizedBox(
            width: 15,
          ),
          DropdownButton<String>(
            value: selectedLanguage,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF302F2F), // 👈 dark charcoal background
            iconEnabledColor: Colors.white, // 👈 dropdown arrow color
            style: const TextStyle(
              color: Colors.white, // 👈 selected value text color
              fontWeight: FontWeight.w500,
            ),
            items: ["English", "Urdu"].map(
                  (lang) => DropdownMenuItem<String>(
                value: lang,
                child: Text(
                  lang,
                  style: const TextStyle(color: Colors.white), // 👈 dropdown list text
                ),
              ),
            ).toList(),
            onChanged: (lang) {
              setState(() {
                selectedLanguage = lang!;
              });
            },
          ),

          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF302F2F), // 👈 dark charcoal background
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HEADER
            SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

            Container(
              width: 70,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // FAQ LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredQA.length,
                itemBuilder: (context, index) {
                  final item = filteredQA[index];
                  final isExpanded =
                      _expandedMap[index] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            item['question'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            onPressed: () {
                              setState(() {
                                _expandedMap[index] = !isExpanded;
                              });
                            },
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            color: Colors.grey.shade200,
                            child: SelectableText(
                              item['answer'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87),
                            )
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // FOOTER MESSAGE
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "For more queries and guidance, you can mail us by clicking the mail icon",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
