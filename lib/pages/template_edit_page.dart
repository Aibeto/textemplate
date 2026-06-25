import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/template.dart';
import '../services/template_storage.dart';
import '../utils/template_engine.dart';

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
  late TextEditingController _regexController;
  late Map<String, TextEditingController> _variableControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _contentController = TextEditingController(text: widget.template.content);
    _regexController = TextEditingController(text: widget.template.variableRegex);
    _variableControllers = {};
    _extractVariables();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _regexController.dispose();
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _extractVariables() {
    final variables = TemplateEngine.extractVariables(
      _contentController.text,
      customRegex: _regexController.text.isNotEmpty ? _regexController.text : null,
    );

    final newControllers = <String, TextEditingController>{};
    for (final variable in variables) {
      newControllers[variable] = _variableControllers[variable] ??
          TextEditingController();
    }

    for (final entry in _variableControllers.entries) {
      if (!newControllers.containsKey(entry.key)) {
        entry.value.dispose();
      }
    }

    setState(() {
      _variableControllers = newControllers;
    });

    return variables;
  }

  String _generateResult() {
    final values = <String, String>{};
    for (final entry in _variableControllers.entries) {
      values[entry.key] = entry.value.text;
    }
    return TemplateEngine.replaceVariables(
      _contentController.text,
      values,
      customRegex: _regexController.text.isNotEmpty ? _regexController.text : null,
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模板名称')),
      );
      return;
    }

    if (!TemplateEngine.isValidRegex(_regexController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正则表达式格式错误')),
      );
      return;
    }

    final updatedTemplate = widget.template.copyWith(
      name: _nameController.text.trim(),
      content: _contentController.text,
      variableRegex: _regexController.text,
      updatedAt: DateTime.now(),
    );

    await widget.storage.updateTemplate(updatedTemplate);
    widget.template.name = updatedTemplate.name;
    widget.template.content = updatedTemplate.content;
    widget.template.variableRegex = updatedTemplate.variableRegex;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }

  void _copyResult() {
    final result = _generateResult();
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
                labelText: '模板名称',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regexController,
              decoration: const InputDecoration(
                labelText: '正则表达式（可选）',
                hintText: r'默认：${变量名}',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _extractVariables(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '模板内容',
                hintText: r'例如：今天有 ${num} 个事情没处理',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              onChanged: (_) {
                _extractVariables();
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            if (_variableControllers.isNotEmpty) ...[
              const Text(
                '变量输入',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._variableControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            const Text(
              '结果预览',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _generateResult(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyResult,
                icon: const Icon(Icons.copy),
                label: const Text('复制结果'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
