/// 模板引擎：提取变量名和替换模板内容。
class TemplateEngine {
  static final RegExp _regex = RegExp(r'\$\{([^}]+)\}');

  static List<String> extractVariables(String content) {
    if (content.isEmpty) return [];

    final variables = <String>{};
    for (final match in _regex.allMatches(content)) {
      variables.add(match.group(1)!);
    }
    return variables.toList();
  }

  static String replaceVariables(String content, Map<String, String> values) {
    if (content.isEmpty) return '';

    return content.replaceAllMapped(_regex, (match) {
      return values[match.group(1)!] ?? '';
    });
  }
}
