import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/template.dart';
import 'services/template_storage.dart';
import 'pages/template_edit_page.dart';

/// 应用入口。初始化存储，创建默认空模板，直接进入编辑页。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = TemplateStorage(prefs);

  if (kDebugMode) {
    print('[main] app starting');
  }

  final now = DateTime.now();
  final defaultTemplate = Template(
    id: const Uuid().v4(),
    name: '',
    createdAt: now,
    updatedAt: now,
  );

  runApp(TextemplateApp(storage: storage, defaultTemplate: defaultTemplate));
}

class TextemplateApp extends StatelessWidget {
  final TemplateStorage storage;
  final Template defaultTemplate;

  const TextemplateApp({
    super.key,
    required this.storage,
    required this.defaultTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'textemplate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansScTextTheme(),
      ),
      home: TemplateEditPage(storage: storage, template: defaultTemplate),
    );
  }
}
