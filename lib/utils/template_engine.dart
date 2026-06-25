class TemplateEngine {
  static final RegExp _defaultRegex = RegExp(r'\$\{([^}]+)\}');

  static List<String> extractVariables(String content, {String? customRegex}) {
    if (content.isEmpty) return [];

    final RegExp regex;
    if (customRegex != null && customRegex.isNotEmpty) {
      try {
        regex = RegExp(customRegex);
      } catch (e) {
        return [];
      }
    } else {
      regex = _defaultRegex;
    }

    final matches = regex.allMatches(content);
    final variables = <String>{};
    for (final match in matches) {
      if (match.groupCount >= 1) {
        variables.add(match.group(1)!);
      }
    }

    return variables.toList();
  }

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
        return content;
      }
    } else {
      regex = _defaultRegex;
    }

    return content.replaceAllMapped(regex, (match) {
      if (match.groupCount >= 1) {
        final variableName = match.group(1)!;
        return values[variableName] ?? '';
      }
      return match.group(0) ?? '';
    });
  }

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
