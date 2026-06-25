import 'package:flutter/foundation.dart';

/// 模板引擎：负责正则提取变量名和替换模板内容。
class TemplateEngine {
  /// 默认正则：匹配 ${变量名} 格式
  static final RegExp _defaultRegex = RegExp(r'\$\{([^}]+)\}');

  /// 从内容中提取所有变量名。
  /// - [content]：模板内容
  /// - [customRegex]：自定义正则表达式（可选，为空则使用默认）
  static List<String> extractVariables(String content, {String? customRegex}) {
    if (content.isEmpty) return [];

    final RegExp regex;
    if (customRegex != null && customRegex.isNotEmpty) {
      try {
        regex = RegExp(customRegex);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[TemplateEngine] extractVariables: invalid regex "$customRegex"',
          );
        }
        return [];
      }
    } else {
      regex = _defaultRegex;
    }

    final matches = regex.allMatches(content);
    final variables = <String>{};
    for (final match in matches) {
      // 有捕获组则取 group(1)，否则取完整匹配 group(0)
      final variableName = match.groupCount >= 1
          ? match.group(1)!
          : match.group(0)!;
      variables.add(variableName);
    }

    if (kDebugMode) {
      print('[TemplateEngine] extractVariables: found $variables');
    }
    return variables.toList();
  }

  /// 将模板内容中的变量替换为对应值。
  /// - [content]：模板内容
  /// - [values]：变量名 → 替换值的映射
  /// - [customRegex]：自定义正则（可选）
  static String replaceVariables(
    String content,
    Map<String, String> values, {
    String? customRegex,
  }) {
    if (content.isEmpty) return '';

    final RegExp regex;
    if (customRegex != null && customRegex.isNotEmpty) {
      try {
        regex = RegExp(customRegex);
      } catch (e) {
        if (kDebugMode) {
          print(
            '[TemplateEngine] replaceVariables: invalid regex, returning original',
          );
        }
        return content;
      }
    } else {
      regex = _defaultRegex;
    }

    return content.replaceAllMapped(regex, (match) {
      final variableName = match.groupCount >= 1
          ? match.group(1)!
          : match.group(0)!;
      return values[variableName] ?? '';
    });
  }

  /// 校验正则表达式字符串是否合法。
  static bool isValidRegex(String regexStr) {
    if (regexStr.isEmpty) return true;
    try {
      RegExp(regexStr);
      return true;
    } catch (e) {
      return false;
    }
  }
}
