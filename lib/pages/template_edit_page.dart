import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../models/template.dart';
import '../services/template_storage.dart';
import '../utils/template_engine.dart';
import 'template_list_page.dart';

/// 模板编辑页面 —— 默认首页。
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
  late TextEditingController _nameController;
  late TextEditingController _contentController;

  final Map<String, TextEditingController> _controllers = {};
  final List<String> _variables = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _contentController = TextEditingController(text: widget.template.content);
    _syncVariables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 从模板内容提取变量，合并手动添加的变量，同步控制器。
  void _syncVariables() {
    final extracted = TemplateEngine.extractVariables(_contentController.text);
    final merged = <String>{..._variables, ...extracted};

    for (final v in merged) {
      _controllers.putIfAbsent(v, () => TextEditingController());
    }
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

  /// 执行变量替换，返回最终文本。
  String _generateResult() {
    final values = <String, String>{};
    for (final entry in _controllers.entries) {
      values[entry.key] = entry.value.text;
    }
    return TemplateEngine.replaceVariables(_contentController.text, values);
  }

  /// 复制结果到剪贴板。
  void _copyResult() {
    final result = _generateResult();
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
    );
  }

  /// 保存模板到本地存储。
  Future<void> _save() async {
    final updated = widget.template.copyWith(
      name: _nameController.text.trim(),
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );

    bool success = await widget.storage.updateTemplate(updated);
    if (!success) {
      success = await widget.storage.addTemplate(updated);
    }

    if (success) {
      widget.template
        ..name = updated.name
        ..content = updated.content;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  /// 打开模板列表页，选择后加载。
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

  /// 加载已有模板，替换当前编辑状态。
  void _loadTemplate(Template template) {
    _nameController.text = template.name;
    _contentController.text = template.content;

    widget.template
      ..name = template.name
      ..content = template.content;

    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _variables.clear();
    _syncVariables();
  }

  /// 弹出对话框手动添加变量。
  Future<void> _addVariable() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加变量'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '变量名',
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
      _controllers[name] = TextEditingController();
      setState(() => _variables.add(name));
    }
  }

  /// 移除变量并释放控制器。
  void _removeVariable(String name) {
    _controllers[name]?.dispose();
    _controllers.remove(name);
    setState(() => _variables.remove(name));
  }

  /// 标题栏：有名显示名，无名显示内容，都无显示默认。
  String get _displayTitle {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    if (_contentController.text.isNotEmpty) return _contentController.text;
    return 'textemplate';
  }

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

            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '模板内容',
                hintText: r'使用 ${变量名} 标记需要替换的部分',
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
