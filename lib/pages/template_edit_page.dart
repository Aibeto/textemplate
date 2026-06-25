import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import '../models/template.dart';
import '../services/template_storage.dart';
import '../utils/template_engine.dart';

/// 模板编辑页面 —— 默认首页。
class TemplateEditPage extends StatefulWidget {
  final TemplateStorage storage;
  final Template template;
  final VoidCallback? onTemplateSaved;

  const TemplateEditPage({
    super.key,
    required this.storage,
    required this.template,
    this.onTemplateSaved,
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
      builder: (context, close) => InfoBar(
        title: const Text('已复制'),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
      duration: const Duration(seconds: 2),
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
        widget.storage.saveLastTemplateId(widget.template.id);
        widget.onTemplateSaved?.call();
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('已保存'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
          duration: const Duration(seconds: 2),
        );
      } else {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('保存失败'),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          ),
          duration: const Duration(seconds: 2),
        );
      }
    }
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
    final theme = FluentTheme.of(context);
    final typography = theme.typography;

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
              tooltip: '复制生成结果到剪贴板',
              onPressed: _copyResult,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('救'),
              tooltip: '保存模板',
              onPressed: _save,
            ),
          ],
        ),
      ),
      content: ScaffoldPage.scrollable(
        padding: const EdgeInsets.all(16),
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
              minLines: 1,
              maxLines: 5,
              onChanged: (_) => _syncVariables(),
            ),
          ),
          const Gap(16),

          const Divider(),
          const Gap(16),

          // 变量区域标题
          Row(
            children: [
              DefaultTextStyle(
                style: typography.subtitle ?? const TextStyle(),
                child: const Text('变量'),
              ),
              const Gap(8),
              FilledButton(onPressed: _addVariable, child: const Text('添加')),
            ],
          ),
          const Gap(8),

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
                      DefaultTextStyle(
                        style: typography.bodyStrong ?? const TextStyle(),
                        child: Text(v),
                      ),
                      const Gap(4),
                      GestureDetector(
                        onTap: () => _removeVariable(v),
                        child: Icon(
                          FluentIcons.delete,
                          size: 16,
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

          const Divider(),
          const Gap(16),

          // 结果预览区
          DefaultTextStyle(
            style: typography.subtitle ?? const TextStyle(),
            child: const Text('结果'),
          ),
          const Gap(8),
          AnimatedSwitcher(
            duration: theme.fastAnimationDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Container(
              key: ValueKey(_generateResult()),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.accentColor.withAlpha(15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DefaultTextStyle(
                style: typography.body ?? const TextStyle(),
                child: SelectableText(_generateResult()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
