import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserQueriesPage extends StatefulWidget {
  @override
  _UserQueriesPageState createState() => _UserQueriesPageState();
}

class _UserQueriesPageState extends State<UserQueriesPage> {
  final TextEditingController _queryController = TextEditingController();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref('user_queries');

  // ---------------- SEND QUERY ----------------
  Future<void> _sendQuery() async {
    if (_queryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a query")),
      );
      return;
    }

    try {
      await dbRef.push().set({
        'userId': userId,
        'query': _queryController.text,
        'timestamp': ServerValue.timestamp,
        'response': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Query sent successfully")),
      );

      _queryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send query")),
      );
    }
  }

  // ------------- BUILD REALTIME LIST -------------
  Widget _buildQueryList({required bool read}) {
    return StreamBuilder(
      stream: dbRef.onValue, // REALTIME UPDATES 🚀
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
              child: Text("No queries found",
                  style: TextStyle(color: Colors.white)));
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        final List<Map> userQueries = [];

        data.forEach((key, value) {
          final q = Map<String, dynamic>.from(value);

          if (q['userId'] == userId) {
            if (read && (q['response'] ?? '') != '') {
              userQueries.add(q);
            } else if (!read && (q['response'] ?? '') == '') {
              userQueries.add(q);
            }
          }
        });

        if (userQueries.isEmpty) {
          return Center(
              child: Text("Nothing here",
                  style: TextStyle(color: Colors.white)));
        }

        return ListView.builder(
          itemCount: userQueries.length,
          itemBuilder: (context, index) {
            final item = userQueries[index];

            return Card(
              color: Colors.grey[850],
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Query: ${item['query']}",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),

                    SizedBox(height: 6),

                    (item['response'] ?? '').isEmpty
                        ? Text("Waiting for admin response...",
                        style: TextStyle(color: Colors.white70))
                        : Text("Admin Response: ${item['response']}",
                        style: TextStyle(color: Colors.greenAccent)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("My Queries", style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: "Unread"),
              Tab(text: "Read"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildQueryList(read: false), // unread
            _buildQueryList(read: true),  // read
          ],
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.pink,
          child: Icon(Icons.add, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("New Query"),
                content: TextField(
                  controller: _queryController,
                  decoration:
                  InputDecoration(hintText: "Enter your query here"),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel")),
                  ElevatedButton(
                    onPressed: () {
                      _sendQuery();
                      Navigator.pop(context);
                    },
                    child: Text("Send"),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
