import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, String>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('model_history/${user.uid}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        history = data.entries.map<Map<String, String>>((e) {
          final val = e.value as Map<dynamic, dynamic>;
          return {
            'name': val['name']?.toString() ?? '',
            'url': val['url']?.toString() ?? '',
            'timestamp': DateTime.fromMillisecondsSinceEpoch(val['timestamp'] ?? 0)
                .toString(),
          };
        }).toList();
      });
    }
  }


  Future<void> _deleteItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('model_history/${user.uid}');
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final keys = (snapshot.value as Map).keys.toList();
    final keyToDelete = keys[index];

    await ref.child(keyToDelete).remove();

    setState(() {
      history.removeAt(index);
    });
  }


  Future<void> _clearAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseDatabase.instance.ref('model_history/${user.uid}').remove();
    setState(() {
      history.clear();
    });
  }


  Future<void> _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:  const Color(0xFF302F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFBC3A),
        title: const Text("Model History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: history.isEmpty ? null : _clearAll,
            tooltip: "Clear all history",
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text("No history yet"))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final name = item['name'] ?? "Model ${index + 1}";
          final url = item['url'] ?? "";
          final time = item['timestamp'] ?? "";

          return Card(

            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(name),
              subtitle: Text(time),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: "Download",
                    onPressed: () => _openUrl(url), // simple download by opening URL
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: "Delete",
                    onPressed: () => _deleteItem(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// -------------------------
/// Image Viewer Page
/// -------------------------
