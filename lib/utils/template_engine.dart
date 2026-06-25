/// 模板引擎：提取变量名和替换模板内容。
class TemplateEngine {
  static final RegExp _defaultRegex = RegExp(r'\$\{([^}]+)\}');

  /// 从内容中提取变量名。customRegex 为空时使用默认 `${}`。
  static List<String> extractVariables(String content, {String? customRegex}) {
    if (content.isEmpty) return [];

    final RegExp regex;
    if (customRegex != null && customRegex.isNotEmpty) {
      try {
        regex = RegExp(customRegex);
      } catch (_) {
        return [];
      }
    } else {
      regex = _defaultRegex;
    }

    final variables = <String>{};
    for (final match in regex.allMatches(content)) {
      final name = match.groupCount >= 1 ? match.group(1)! : match.group(0)!;
      variables.add(name);
    }
    return variables.toList();
  }

  /// 将模板中的变量替换为对应值。
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
      } catch (_) {
        return content;
      }
    } else {
      regex = _defaultRegex;
    }

    return content.replaceAllMapped(regex, (match) {
      final name = match.groupCount >= 1 ? match.group(1)! : match.group(0)!;
      return values[name] ?? '';
    });
  }
}
