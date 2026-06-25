/// 模板数据模型。
class Template {
  final String id;
  String name;
  String content;
  String variableRegex;
  final DateTime createdAt;
  DateTime updatedAt;

  Template({
    required this.id,
    required this.name,
    this.content = '',
    this.variableRegex = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 创建副本，可选覆盖指定字段。
  Template copyWith({
    String? id,
    String? name,
    String? content,
    String? variableRegex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      variableRegex: variableRegex ?? this.variableRegex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'variableRegex': variableRegex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON 反序列化。
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String? ?? '',
      variableRegex: json['variableRegex'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}