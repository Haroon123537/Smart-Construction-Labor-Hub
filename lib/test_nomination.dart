import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocationSearchPage(),
    );
  }
}

class LocationSearchPage extends StatefulWidget {
  @override
  _LocationSearchPageState createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  TextEditingController _controller = TextEditingController();
  List _results = [];

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=10');
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

    if (response.statusCode == 200) {
      setState(() {
        _results = jsonDecode(response.body);
      });
    } else {
      setState(() => _results = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a location...",
                border: OutlineInputBorder(),
              ),
              onChanged: searchLocation,
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  var loc = _results[index];
                  return ListTile(
                    title: Text(loc['display_name']),
                    subtitle: Text(
                        "Lat: ${loc['lat']}, Lon: ${loc['lon']}"),
                    onTap: () {
                      // Do something with the selected location
                      print("Selected: ${loc['display_name']}");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
