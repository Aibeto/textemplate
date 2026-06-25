import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template.dart';

/// 基于 SharedPreferences 的模板存储服务。
class TemplateStorage {
  static const String _storageKey = 'templates';
  final SharedPreferences _prefs;

  TemplateStorage(this._prefs);

  /// 加载所有模板。
  Future<List<Template>> loadTemplates() async {
    final String? data = _prefs.getString(_storageKey);
    if (data == null || data.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
    final templates = jsonList
        .map((item) => Template.fromJson(item as Map<String, dynamic>))
        .toList();

    if (kDebugMode) {
      print(
        '[TemplateStorage] loadTemplates: loaded ${templates.length} templates',
      );
    }
    return templates;
  }

  /// 保存模板列表到本地。
  Future<bool> saveTemplates(List<Template> templates) async {
    final List<Map<String, dynamic>> jsonList = templates
        .map((t) => t.toJson())
        .toList();
    final String data = json.encode(jsonList);
    final result = _prefs.setString(_storageKey, data);

    if (kDebugMode) {
      print(
        '[TemplateStorage] saveTemplates: ${templates.length} templates, success=$result',
      );
    }
    return result;
  }

  /// 添加新模板。
  Future<bool> addTemplate(Template template) async {
    final templates = await loadTemplates();
    templates.add(template);
    if (kDebugMode) {
      print('[TemplateStorage] addTemplate: id=${template.id}');
    }
    return saveTemplates(templates);
  }

  /// 通过 ID 更新已有模板。返回 false 表示模板不存在。
  Future<bool> updateTemplate(Template template) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      if (kDebugMode) {
        print(
          '[TemplateStorage] updateTemplate: template not found, id=${template.id}',
        );
      }
      return false;
    }
    templates[index] = template;
    if (kDebugMode) {
      print('[TemplateStorage] updateTemplate: id=${template.id}');
    }
    return saveTemplates(templates);
  }

  /// 通过 ID 删除模板。
  Future<bool> deleteTemplate(String id) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == id);
    if (kDebugMode) {
      print('[TemplateStorage] deleteTemplate: id=$id');
    }
    return saveTemplates(templates);
  }
}
