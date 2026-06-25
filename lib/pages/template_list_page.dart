import 'package:fluent_ui/fluent_ui.dart';
import 'package:uuid/uuid.dart';
import '../models/template.dart';
import '../services/template_storage.dart';

/// 模板列表页面。
class TemplateListPage extends StatefulWidget {
  final TemplateStorage storage;

  const TemplateListPage({super.key, required this.storage});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  List<Template> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
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
    if (mounted) {
      Navigator.pop(context, template);
    }
  }

  Future<void> _deleteTemplate(Template template) async {
    final displayName = template.name.isNotEmpty
        ? template.name
        : template.content;
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除 "$displayName" 吗？'),
        actions: [
          Button(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(ctx),
          ),
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
    return ScaffoldPage(
      header: PageHeader(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('模板列表'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('新建'),
              onPressed: _createTemplate,
            ),
          ],
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : _templates.isEmpty
              ? const Center(
                  child: Text(
                    '暂无模板\n点击右上角按钮新建',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _templates.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final displayTitle = template.name.isNotEmpty
                        ? template.name
                        : (template.content.isNotEmpty
                            ? template.content
                            : '空模板');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatDate(template.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(FluentIcons.delete),
                          onPressed: () => _deleteTemplate(template),
                        ),
                        onPressed: () => Navigator.pop(context, template),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}