import 'package:fluent_ui/fluent_ui.dart';
import 'package:uuid/uuid.dart';
import '../models/template.dart';
import '../services/template_storage.dart';

/// 模板列表页面。
class TemplateListPage extends StatefulWidget {
  final TemplateStorage storage;
  final void Function(Template)? onTemplateSelected;
  final ValueNotifier<int> templateVersion;

  const TemplateListPage({
    super.key,
    required this.storage,
    this.onTemplateSelected,
    required this.templateVersion,
  });

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  List<Template> _templates = [];
  bool _isLoading = true;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    widget.templateVersion.addListener(_loadTemplates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  void dispose() {
    widget.templateVersion.removeListener(_loadTemplates);
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final templates = await widget.storage.loadTemplates();
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  Future<void> _createTemplate() async {
    final now = DateTime.now();
    final template = Template(
      id: const Uuid().v4(),
      name: '',
      createdAt: now,
      updatedAt: now,
    );
    await widget.storage.addTemplate(template);
    _loadTemplates();
    widget.onTemplateSelected?.call(template);
  }

  Future<void> _deleteTemplate(Template template) async {
    final displayName = template.name.isNotEmpty
        ? template.name
        : (template.content.isNotEmpty ? template.content : '空模板');
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除 "$displayName" 吗？'),
        actions: [
          Button(child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
    );

    if (confirm == 'delete') {
      await widget.storage.deleteTemplate(template.id);
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final typography = theme.typography;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('模板列表'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('新建'),
              tooltip: '创建新模板',
              onPressed: _createTemplate,
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : AnimatedOpacity(
              opacity: _opacity,
              duration: theme.fastAnimationDuration,
              curve: Curves.easeOut,
              child: _templates.isEmpty
                  ? Center(
                      child: DefaultTextStyle(
                        style:
                            typography.body ??
                            const TextStyle(color: Colors.grey),
                        child: const Text(
                          '暂无模板\n点击右上角 + 新建',
                          textAlign: TextAlign.center,
                          // style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _templates.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        final displayTitle = template.name.isNotEmpty
                            ? template.name
                            : (template.content.isNotEmpty
                                  ? template.content
                                  : '空模板');
                        final subtitle =
                            template.name.isNotEmpty &&
                                template.content.isNotEmpty
                            ? template.content
                            : _formatDate(template.updatedAt);
                        return _TemplateCard(
                          template: template,
                          displayTitle: displayTitle,
                          subtitle: subtitle,
                          animationDelay: index * 50,
                          onTap: () =>
                              widget.onTemplateSelected?.call(template),
                          onDelete: () => _deleteTemplate(template),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 带交错淡入 + 平移动画的模板卡片。
class _TemplateCard extends StatefulWidget {
  final Template template;
  final String displayTitle;
  final String subtitle;
  final int animationDelay;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.displayTitle,
    required this.subtitle,
    required this.animationDelay,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Card(
          margin: const EdgeInsets.only(bottom: 6),
          borderRadius: BorderRadius.circular(4),
          child: ListTile(
            title: Text(
              widget.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: widget.onDelete,
            ),
            onPressed: widget.onTap,
          ),
        ),
      ),
    );
  }
}
