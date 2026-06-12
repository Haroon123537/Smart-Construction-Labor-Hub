import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Help page.dart';
import 'home_screen.dart';
import 'package:smart_constuction_hub/splash_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'history_Page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_services.dart';
import 'package:firebase_database/firebase_database.dart';

class Meshy3DPage extends StatefulWidget {
  const Meshy3DPage({super.key});

  @override
  State<Meshy3DPage> createState() => _Meshy3DPageState();
}

class _Meshy3DPageState extends State<Meshy3DPage> {
  String _statusText = "";
  String? _currentTaskId;
  bool loading = false;

  String selectedLanguage = 'English';
  String searchQuery = '';

  final TextEditingController _promptController = TextEditingController();
  late TextEditingController _searchController;

  late stt.SpeechToText _speech;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: searchQuery);
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  List<String> modelHistory = [];

  void _openHistory() {
    // later you can open a page or dialog
    print(modelHistory);
  }

  void _clearHistory() {
    setState(() {
      modelHistory.clear();
    });
  }

  Future<void> autoDownloadModel(String url) async {
    final fileName = url.split('/').last;

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..style.display = 'none';

    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }



  Future<void> generate3DModel() async {
    debugPrint("🚀 generate3DModel() started");
    setState(() {
      loading = true;
      _statusText = "⏳ Generating model... Preview in progress..."; // ← add it here
    });

    const apiKey = "msy_lP3UGsDacuS4VaCa9edHlzaEs0tp8trvoKB5";
    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json"
    };

    try {
      // 1️⃣ Create preview task
      final body = jsonEncode({
        "mode": "preview",
        "prompt":_promptController.text.trim(),
        "art_style": "realistic",
        "should_remesh": true
      });

      final createResp = await http.post(
        Uri.parse("https://api.meshy.ai/openapi/v2/text-to-3d"),
        headers: headers,
        body: body,
      );

// ✅ Instead of throwing immediately, check if "result" exists
      final respJson = jsonDecode(createResp.body);
      if (!respJson.containsKey('result')) {
        throw Exception("Failed to create preview task: ${createResp.body}");
      }

      final taskId = respJson['result'];
      print("Preview task created. Task ID: $taskId");

      setState(() {
        _currentTaskId = taskId;  // ← This makes task_id available in the UI
        _statusText = "⏳ Preview task started. Task ID: $taskId";
      });

      // 2️⃣ Poll preview task until done
      Map<String, dynamic> previewData;
      int pollCount = 0;
      const int pollIntervalSeconds = 15;
      while (true) {
        pollCount++;
        final statusResp = await http.get(
          Uri.parse("https://api.meshy.ai/openapi/v2/text-to-3d/$taskId"),
          headers: headers,
        );
        if (statusResp.statusCode != 200) {
          throw Exception("Preview polling failed: ${statusResp.body}");
        }
        previewData = jsonDecode(statusResp.body);
        final status = previewData['status'];
        setState(() => _statusText = "⏳ Preview step: attempt $pollCount, status: $status");
        if (status == 'FAILED') {
          final errMsg = previewData['task_error']?['message']?.toString() ?? '';
          debugPrint("❌ Preview task failed: $errMsg");
          print("👉 Error message: ${previewData['error']}");
          print("👉 Task error details: ${previewData['task_error']}");
          if (errMsg.contains("server is busy")) {
            print("⏳ Server busy — waiting and retrying preview...");
            await Future.delayed(const Duration(seconds: 30));
            return generate3DModel(); // retry whole flow
          }

          setState(() => loading = false);
          return;
        }

        if (status == 'SUCCEEDED') break;
        print("⏳ waiting 15 seconds before next poll…");
        await Future.delayed(Duration(seconds: pollIntervalSeconds));
      }

      print("Preview task succeeded!");

      final refineBody = jsonEncode({
        "mode": "refine",
        "preview_task_id": taskId,
        "enable_pbr": true,
        "texture_resolution": "4k",
        "high_poly": true
      });

      final refineResp = await http.post(
        Uri.parse("https://api.meshy.ai/openapi/v2/text-to-3d"),
        headers: headers,
        body: refineBody,
      );
      final refineJson = jsonDecode(refineResp.body);

      if (!refineJson.containsKey('result')) {
        await Future.delayed(const Duration(seconds: 20));
        return generate3DModel(); // retry whole flow
      }

      final refinedTaskId = refineJson['result'];
      debugPrint("Refine task created. Task ID: $refinedTaskId");

      Map<String, dynamic> refinedData;
      pollCount = 0;

      while (true) {
        pollCount++;
        final statusResp = await http.get(
          Uri.parse("https://api.meshy.ai/openapi/v2/text-to-3d/$refinedTaskId"),
          headers: headers,
        );

        if (statusResp.statusCode != 200) {
          throw Exception("Refine polling failed: ${statusResp.body}");
        }

        refinedData = jsonDecode(statusResp.body);
        final status = refinedData['status'];
        setState(() => _statusText = "🔄 Refining model: attempt $pollCount, status: $status");

        if (status == 'FAILED') {
          debugPrint("❌ Refine task failed: ${refinedData['task_error']}");
          print("👉 Error message: ${refinedData['error']}");
          print("👉 Task error details: ${refinedData['task_error']}");
          setState(() => loading = false);
          return;
        }

        if (status == 'SUCCEEDED') break;
        print("⏳ waiting 15 seconds before next poll…");
        await Future.delayed(Duration(seconds: pollIntervalSeconds));
      }

      print("Refine task succeeded!");

      // 5️⃣ Update WebView with refined model
      final String? refinedGlbUrl =
      refinedData['model_urls']['glb'] as String?;

      if (refinedGlbUrl != null) {
        final proxyUrl = Uri.encodeComponent(refinedGlbUrl);
        final finalModelUrl = refinedGlbUrl; // Direct URL


        // 1️⃣ Save model
        await saveGeneratedModel(
          modelName: "Model ${modelHistory.length + 1}",
          modelUrl: finalModelUrl,
        );

     //   await autoDownloadModel(refinedGlbUrl);
        await autoDownloadModel(refinedGlbUrl);

// 3️⃣ Update UI only
        if (!mounted) return;

        setState(() {
          loading = false;
          modelHistory.add(finalModelUrl);
          _statusText = "✅ Model generated, saved & downloaded!";
        });

        // 3️⃣ Show model on screen
      }



      // Trigger auto-download


      debugPrint("✅ Refined model ready! URL: $refinedGlbUrl");

    } catch (e) {
      print("Error generating 3D model: $e");

      if (mounted) {
        setState(() {
          _statusText = "Something went wrong. Try again.";
          loading = false;
        });
      }
    }
  }

  void _generateModel() {
    debugPrint("🎯 Generate button tapped with prompt: ${_promptController.text}");
    print("🎯 Button tapped");
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _statusText = "Please enter a description first.";
      });
      return;
    }
    // Update prompt usage in API
    setState(() {
      _statusText = "⏳ Generating model... Preview in progress...";
    });
    generate3DModel();
  }

  Future<void> saveToHistory(String url, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('model_history');
    List<Map<String, String>> history = data != null
        ? (jsonDecode(data) as List)
        .map<Map<String, String>>((e) => Map<String, String>.from(e))
        .toList()
        : [];

    history.add({
      'url': url,
      'name': name ?? "Model ${history.length + 1}",
      'timestamp': DateTime.now().toString(),
    });

    prefs.setString('model_history', jsonEncode(history));
  }

//  Future<void> autoDownloadModel(String url) async {
  //  final anchor = html.AnchorElement(href: url)
    //  ..download = url.split('/').last
   //   ..target = 'blank';
    //html.document.body!.append(anchor);
   // anchor.click();
    //anchor.remove();
 // }


  Future<void> saveGeneratedModel({
    required String modelName,
    required String modelUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final databaseRef = FirebaseDatabase.instance.ref('model_history/$userId').push();

    try {
      await databaseRef.set({
        'name': modelName,
        'url': modelUrl,
        'timestamp': timestamp,
        'userId': userId,
      });
      print("Model saved successfully!");
    } catch (error) {
      print("Failed to save model: $error");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meshy 3D Viewer",
        style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700
        ),
      ),
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

              // create email response notification for CURRENT USER
              await NotificationService.notifyEmailReceived();

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
              width:12
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.density_medium, size: 25, color: const Color(0xFF302F2F)),
            onSelected: (value) {
              if (value == "history") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              } else if (value == "clear") {
                _clearHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "history",
                child: Text("View history"),
              ),
              const PopupMenuItem(
                value: "clear",
                child: Text("Clear all history"),
              ),
            ],
          ),
          SizedBox(
            width: 10,
          )
        ],

      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/house2.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Scrollable content (Text, TextField, Status, etc.)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min, // shrink to fit content
                      children: [
                        const Text(
                          '🏠 3D House Generator',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Enter your house description:",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            TextField(
                              controller: _promptController,
                              maxLines: 9,
                              maxLength: 800,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Describe the house you want...",
                                hintStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                counterStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 26,
                              right: 6,
                              child: AvatarGlow(
                                animate: isListening,
                                glowColor: Colors.blue,
                                duration: const Duration(milliseconds: 2000),
                                repeat: true,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  icon: const Icon(Icons.mic, color: Colors.blue, size: 15),
                                  onPressed: () async {
                                    if (!isListening) {
                                      bool available = await _speech.initialize();
                                      if (available) {
                                        setState(() => isListening = true);
                                        _speech.listen(onResult: (val) {
                                          setState(() {
                                            _searchController.text = val.recognizedWords;
                                            searchQuery = val.recognizedWords;
                                          });
                                        });
                                      }
                                    } else {
                                      setState(() => isListening = false);
                                      _speech.stop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _statusText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentTaskId != null) // ✅ conditional widget
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "Task ID: $_currentTaskId",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Generate Model button directly below TextField
                Padding(
                  padding: const EdgeInsets.only(top: 12), // small gap from TextField
                  child: SizedBox(
                    width: 200, // desired width
                    child: ElevatedButton(
                      onPressed: loading ? null : _generateModel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFBC3A),
                        padding: const EdgeInsets.symmetric(vertical: 12), // controls height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        elevation: 4,
                      ),
                      child: loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Generate Model",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
