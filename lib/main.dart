import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/template_storage.dart';
import 'pages/template_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = TemplateStorage(prefs);

  runApp(TextemplateApp(storage: storage));
}

class TextemplateApp extends StatelessWidget {
  final TemplateStorage storage;

  const TextemplateApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'textemplate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: TemplateListPage(storage: storage),
    );
  }
}
