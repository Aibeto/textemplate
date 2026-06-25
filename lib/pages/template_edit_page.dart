import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
    displayInfoBar(
      context,
      builder: (context, close) =>
          const InfoBar(title: Text('已复制'), severity: InfoBarSeverity.success),
      duration: const Duration(seconds: 1),
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

    if (mounted) {
      if (success) {
        widget.template
          ..name = updated.name
          ..content = updated.content;
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('已保存'),
            severity: InfoBarSeverity.success,
          ),
          duration: const Duration(seconds: 1),
        );
      } else {
        displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('保存失败'),
            severity: InfoBarSeverity.error,
          ),
          duration: const Duration(seconds: 1),
        );
      }
    }
  }

  /// 打开模板列表页，选择后加载。
  Future<void> _openListPage() async {
    final result = await Navigator.push<Template>(
      context,
      FluentPageRoute(
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
      builder: (ctx) => ContentDialog(
        title: const Text('添加变量'),
        content: SizedBox(
          height: 32,
          child: TextBox(
            controller: controller,
            autofocus: true,
            placeholder: '变量名',
            maxLines: 1,
          ),
        ),
        actions: [
          Button(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            child: const Text('添加'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
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

  /// 标题栏：有名显示名，无名显示内容首行，都无显示默认。
  String get _displayTitle {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return name;
    final content = _contentController.text.trim();
    if (content.isNotEmpty) {
      final firstLine = content.split('\n').first;
      return firstLine.length > 40
          ? '${firstLine.substring(0, 40)}...'
          : firstLine;
    }
    return 'textemplate';
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(
          _displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.copy),
              label: const Text('复制结果'),
              onPressed: _copyResult,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('保存'),
              onPressed: _save,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.list),
              label: const Text('模板列表'),
              onPressed: _openListPage,
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: '模板名称（可选）',
              child: TextBox(
                controller: _nameController,
                placeholder: '留空则显示模板内容',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Gap(16),

            InfoLabel(
              label: '模板内容',
              child: TextBox(
                controller: _contentController,
                // placeholder: r'使用 ${变量名} 标记需要替换的部分',
                minLines: 1,
                maxLines: 5,
                onChanged: (_) => _syncVariables(),
              ),
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
                const Gap(8),
                Button(
                  onPressed: _addVariable,
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  child: const Text('添加'),
                ),
              ],
            ),
            const Gap(12),

            ..._variables.map((v) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(v, style: const TextStyle(fontSize: 14)),
                        const Gap(4),
                        GestureDetector(
                          onTap: () => _removeVariable(v),
                          child: Icon(
                            FluentIcons.delete,
                            size: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    TextBox(
                      key: ValueKey(v),
                      controller: _controllers[v],
                      placeholder: '输入"$v"的内容',
                      maxLines: null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
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
                color: FluentTheme.of(context).accentColor.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
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
