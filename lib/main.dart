import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/template.dart';
import 'services/template_storage.dart';
import 'pages/template_edit_page.dart';
import 'pages/template_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = TemplateStorage(prefs);

  runApp(TextemplateApp(storage: storage));
}

/// 应用根组件，配置 Fluent UI 主题。
class TextemplateApp extends StatelessWidget {
  final TemplateStorage storage;

  const TextemplateApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'textemplate',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        focusTheme: const FocusThemeData(glowFactor: 0.0),
        // fontFamily 通过 Typography.apply(fontFamily:) 附加到默认字体系列，
        // 自动保留 Typography.fromBrightness() 的所有默认属性（颜色、字重、尺寸、行高）。
        fontFamily: 'Maple Mono NF CN',
      ),
      home: HomePage(storage: storage),
      builder: (context, child) => NavigationPaneTheme(
        data: NavigationPaneThemeData(backgroundColor: Colors.transparent),
        child: ExcludeSemantics(child: child!),
      ),
    );
  }
}

/// 主导航页面，使用 Stack 保持所有页面存活，避免切换时
/// displayInfoBar / CommandBar 在 deactivated context 上报错。
class HomePage extends StatefulWidget {
  final TemplateStorage storage;

  const HomePage({super.key, required this.storage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _paneIndex = 0;
  late Template _currentTemplate;
  final ValueNotifier<int> _templateVersion = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _currentTemplate = Template(
      id: const Uuid().v4(),
      name: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastTemplate();
    });
  }

  @override
  void dispose() {
    _templateVersion.dispose();
    super.dispose();
  }

  Future<void> _loadLastTemplate() async {
    final lastId = await widget.storage.getLastTemplateId();
    if (lastId == null) return;

    final templates = await widget.storage.loadTemplates();
    final lastTemplate = templates.cast<Template?>().firstWhere(
      (t) => t?.id == lastId,
      orElse: () => null,
    );
    if (lastTemplate != null && mounted) {
      setState(() => _currentTemplate = lastTemplate);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('欢迎回来，已加载上次编辑的模板'),
              severity: InfoBarSeverity.info,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            ),
            duration: const Duration(seconds: 2),
          );
        }
      });
    }
  }

  void _onTemplateSelected(Template template) {
    setState(() {
      _currentTemplate = template;
      _paneIndex = 0;
    });
  }

  void _onTemplateSaved() {
    _templateVersion.value++;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    bool isSelected(int i) => i == _paneIndex;

    return Row(
      children: [
        // 侧边栏 —— 模拟 fluent_ui compact 导航面板
        Container(
          width: 48,
          color:
              theme.navigationPaneTheme.backgroundColor ??
              theme.scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _NavIcon(
                icon: FluentIcons.edit,
                tooltip: '编辑',
                selected: isSelected(0),
                onTap: () => setState(() => _paneIndex = 0),
              ),
              const SizedBox(height: 4),
              _NavIcon(
                icon: FluentIcons.list,
                tooltip: '模板列表',
                selected: isSelected(1),
                onTap: () => setState(() => _paneIndex = 1),
              ),
            ],
          ),
        ),
        // 内容区域 —— Stack + AnimatedOpacity 淡入淡出切换
        Expanded(
          child: Stack(
            children: [
              _PageTransition(
                visible: _paneIndex == 0,
                child: TemplateEditPage(
                  key: ValueKey(_currentTemplate.id),
                  storage: widget.storage,
                  template: _currentTemplate,
                  onTemplateSaved: _onTemplateSaved,
                ),
              ),
              _PageTransition(
                visible: _paneIndex == 1,
                child: TemplateListPage(
                  storage: widget.storage,
                  onTemplateSelected: _onTemplateSelected,
                  templateVersion: _templateVersion,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 带淡入淡出动画的页面包装器，通过 [visible] 控制显示/隐藏。
class _PageTransition extends StatelessWidget {
  final bool visible;
  final Widget child;

  const _PageTransition({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: theme.fastAnimationDuration,
      curve: Curves.easeInOut,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}

/// 侧边栏导航图标按钮，使用 AnimatedContainer 实现选中指示器动画。
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final color = selected ? theme.accentColor : theme.inactiveColor;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: theme.fastAnimationDuration,
          curve: Curves.easeInOut,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? theme.accentColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: theme.fastAnimationDuration,
            style: TextStyle(color: color),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
