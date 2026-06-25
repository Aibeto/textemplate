import 'package:flutter/material.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除 "$displayName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.storage.deleteTemplate(template.id);
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模板列表'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? const Center(
              child: Text(
                '暂无模板\n点击右下角按钮新建',
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
                    : (template.content.isNotEmpty ? template.content : '空模板');
                return Card(
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
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTemplate(template),
                    ),
                    onTap: () => Navigator.pop(context, template),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}