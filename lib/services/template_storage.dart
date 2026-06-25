import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template.dart';

class TemplateStorage {
  static const String _storageKey = 'templates';
  final SharedPreferences _prefs;

  TemplateStorage(this._prefs);

  Future<List<Template>> loadTemplates() async {
    final String? data = _prefs.getString(_storageKey);
    if (data == null || data.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
    return jsonList
        .map((item) => Template.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> saveTemplates(List<Template> templates) async {
    final List<Map<String, dynamic>> jsonList =
        templates.map((t) => t.toJson()).toList();
    final String data = json.encode(jsonList);
    return _prefs.setString(_storageKey, data);
  }

  Future<bool> addTemplate(Template template) async {
    final templates = await loadTemplates();
    templates.add(template);
    return saveTemplates(templates);
  }

  Future<bool> updateTemplate(Template template) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index == -1) return false;
    templates[index] = template;
    return saveTemplates(templates);
  }

  Future<bool> deleteTemplate(String id) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == id);
    return saveTemplates(templates);
  }
}
