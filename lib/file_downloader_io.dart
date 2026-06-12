import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File> downloadFileFromUrl(String url) async {
  final response = await http.get(Uri.parse(url));
  final dir = await getApplicationDocumentsDirectory();
  final fileName = url.split('/').last;
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(response.bodyBytes);
  return file;
}
