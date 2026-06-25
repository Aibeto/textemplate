import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/template.dart';
import 'services/template_storage.dart';
import 'pages/template_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = TemplateStorage(prefs);

  final now = DateTime.now();
  final defaultTemplate = Template(
    id: const Uuid().v4(),
    name: '',
    createdAt: now,
    updatedAt: now,
  );

  runApp(TextemplateApp(storage: storage, defaultTemplate: defaultTemplate));
}

/// 应用根组件，配置 Fluent UI 主题。
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
    return FluentApp(
      title: 'textemplate',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        typography: Typography.raw(
          caption: TextStyle(fontFamily: 'Source Han Sans SC'),
          body: TextStyle(fontFamily: 'Source Han Sans SC'),
          bodyStrong: TextStyle(fontFamily: 'Source Han Sans SC'),
          bodyLarge: TextStyle(fontFamily: 'Source Han Sans SC'),
          subtitle: TextStyle(fontFamily: 'Source Han Sans SC'),
          title: TextStyle(fontFamily: 'Source Han Sans SC'),
          titleLarge: TextStyle(fontFamily: 'Source Han Sans SC'),
          display: TextStyle(fontFamily: 'Source Han Sans SC'),
        ),
      ),
      home: TemplateEditPage(storage: storage, template: defaultTemplate),
    );
  }
}
