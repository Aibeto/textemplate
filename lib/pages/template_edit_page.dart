import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../models/template.dart';
import '../services/template_storage.dart';
import '../utils/template_engine.dart';
import 'template_list_page.dart';

/// 模板编辑页面 —— 也是应用的默认首页。
/// 负责模板名称、内容、正则表达式的编辑，以及变量输入和结果预览。
class TemplateEditPage extends StatefulWidget {
  final TemplateStorage storage;
  final Template template;

  const TemplateEditPage({
    super.key,
    required this.storage,
    required this.template,
  });

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  // ---- 控制器 ----
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextEditingController _regexController;

  /// 每个变量名 → 对应的输入框控制器
  final Map<String, TextEditingController> _controllers = {};

  /// 当前所有变量名（从内容提取 + 手动添加）
  final List<String> _variables = [];

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('[TemplateEditPage] initState, template.id=${widget.template.id}');
    }

    _nameController = TextEditingController(text: widget.template.name);
    _contentController = TextEditingController(text: widget.template.content);
    _regexController = TextEditingController(
      text: widget.template.variableRegex,
    );
    _syncVariables();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('[TemplateEditPage] dispose, template.id=${widget.template.id}');
    }
    _nameController.dispose();
    _contentController.dispose();
    _regexController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ==================== 变量同步 ====================

  /// 从模板内容中提取变量，与手动添加的变量合并，同步控制器映射。
  void _syncVariables() {
    final extracted = TemplateEngine.extractVariables(
      _contentController.text,
      customRegex: _regexController.text.isNotEmpty
          ? _regexController.text
          : null,
    );

    if (kDebugMode) {
      print(
        '[TemplateEditPage] _syncVariables: extracted=$extracted, existing=$_variables',
      );
    }

    // 合并：保留手动添加的变量，加入新提取的变量
    final merged = <String>{..._variables, ...extracted};

    // 为新变量创建控制器
    for (final v in merged.toList()) {
      _controllers.putIfAbsent(v, () => TextEditingController());
    }

    // 清理已不存在的变量控制器
    for (final v in _controllers.keys.toList()) {
      if (!merged.contains(v)) {
        _controllers[v]!.dispose();
        _controllers.remove(v);
      }
    }

    setState(() {
      _variables
        ..clear()
        ..addAll(merged);
    });
  }

  // ==================== 结果生成与复制 ====================

  /// 收集所有变量的输入值，执行模板替换，返回最终文本。
  String _generateResult() {
    final values = <String, String>{};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text;
    }
    return TemplateEngine.replaceVariables(
      _contentController.text,
      values,
      customRegex: _regexController.text.isNotEmpty
          ? _regexController.text
          : null,
    );
  }

  /// 将生成结果复制到系统剪贴板。
  void _copyResult() {
    final result = _generateResult();
    Clipboard.setData(ClipboardData(text: result));
    if (kDebugMode) {
      print('[TemplateEditPage] _copyResult: "$result"');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  // ==================== 持久化 ====================

  /// 保存当前模板到本地存储。
  /// 新模板（从未保存过）会走 addTemplate，已有模板走 updateTemplate。
  Future<void> _save() async {
    if (!TemplateEngine.isValidRegex(_regexController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正则表达式格式错误')));
      return;
    }

    final name = _nameController.text.trim();
    final content = _contentController.text;

    final updated = widget.template.copyWith(
      name: name,
      content: content,
      variableRegex: _regexController.text,
      updatedAt: DateTime.now(),
    );

    // 尝试更新；若模板不存在于存储中（新建模板），则改为添加
    bool success = await widget.storage.updateTemplate(updated);
    if (!success) {
      if (kDebugMode) {
        print(
          '[TemplateEditPage] _save: updateTemplate failed, trying addTemplate',
        );
      }
      success = await widget.storage.addTemplate(updated);
    }

    if (success) {
      // 同步 widget.template 引用（非理想做法，但避免大范围重构）
      widget.template.name = updated.name;
      widget.template.content = updated.content;
      widget.template.variableRegex = updated.variableRegex;

      if (kDebugMode) {
        print('[TemplateEditPage] _save: success, id=${updated.id}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      if (kDebugMode) {
        print('[TemplateEditPage] _save: FAILED');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  // ==================== 导航 ====================

  /// 打开模板列表页面，用户选择模板后回传当前页加载。
  Future<void> _openListPage() async {
    final result = await Navigator.push<Template>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateListPage(storage: widget.storage),
      ),
    );
    if (result != null) {
      _loadTemplate(result);
    }
  }

  /// 加载一个已有模板，替换当前编辑状态。
  void _loadTemplate(Template template) {
    if (kDebugMode) {
      print(
        '[TemplateEditPage] _loadTemplate: id=${template.id}, name="${template.name}"',
      );
    }

    _nameController.text = template.name;
    _contentController.text = template.content;
    _regexController.text = template.variableRegex;

    // 同步 widget.template 引用
    widget.template.name = template.name;
    widget.template.content = template.content;
    widget.template.variableRegex = template.variableRegex;

    // 清空并重建变量状态
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _variables.clear();
    _syncVariables();
  }

  // ==================== 变量增删 ====================

  /// 弹出对话框，手动添加一个变量。
  Future<void> _addVariable() async {
    if (kDebugMode) {
      print('[TemplateEditPage] _addVariable: dialog opened');
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加变量'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入变量名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name != null && name.isNotEmpty && !_variables.contains(name)) {
      if (kDebugMode) {
        print('[TemplateEditPage] _addVariable: added "$name"');
      }
      _controllers[name] = TextEditingController();
      setState(() => _variables.add(name));
    }
  }

  /// 移除指定变量，同时释放其控制器。
  void _removeVariable(String name) {
    if (kDebugMode) {
      print('[TemplateEditPage] _removeVariable: "$name"');
    }
    _controllers[name]?.dispose();
    _controllers.remove(name);
    setState(() => _variables.remove(name));
  }

  // ==================== UI 辅助 ====================

  /// 标题栏显示逻辑：有名显示名，无名显示内容，都无则显示默认名称。
  String get _displayTitle {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    if (_contentController.text.isNotEmpty) return _contentController.text;
    return 'textemplate';
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.list),
          tooltip: '模板列表',
          onPressed: _openListPage,
        ),
        title: Text(_displayTitle),
        actions: [
          // 复制按钮：文字 + 图标，清晰可见
          TextButton.icon(
            onPressed: _copyResult,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制结果'),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存模板',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 模板名称 ----
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '模板名称（可选）',
                hintText: '留空则显示模板内容',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Gap(16),

            // ---- 模板内容 ----
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '模板内容',
                hintText: r'变量部分字段将被替换为实际内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 1,
              maxLines: 5,
              onChanged: (_) => _syncVariables(),
            ),
            const Gap(24),

            const Divider(),
            const Gap(12),

            // ---- 变量区域 ----
            Row(
              children: [
                const Text(
                  '变量',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addVariable,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            // ---- 变量标签（自动换行） ----
            if (_variables.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _variables.map((v) {
                  return InputChip(
                    label: Text(v, style: const TextStyle(fontSize: 13)),
                    onDeleted: () => _removeVariable(v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            const Gap(12),

            // ---- 变量输入框（垂直平铺全部展示） ----
            ..._variables.map((v) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  key: ValueKey(v),
                  controller: _controllers[v],
                  decoration: InputDecoration(
                    labelText: v,
                    hintText: '输入"$v"的内容',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
            }),
            const Gap(4),

            const Divider(),
            const Gap(12),

            // ---- 结果预览 ----
            const Text(
              '结果',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _generateResult(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
