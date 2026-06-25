# AGENTS.md

## 项目概览

**textemplate** — 文本模板生成器，基于 `fluent_ui` 构建的 Windows 桌面应用。用户定义含 `${变量}` 占位符的模板，填写变量值后实时生成最终文本并一键复制。

## 技术栈

| 层 | 选型 |
|---|------|
| UI 框架 | `fluent_ui: ^4.10.1`（Win11 风格） |
| 间距 | `gap: ^3.0.1`（`Gap` 替代 `SizedBox`） |
| 字体 | 系统字体 `Source Han Sans SC`（思源黑体），通过 `Typography.raw()` 配置 |
| 持久化 | `shared_preferences`（JSON 序列化模板列表） |
| ID 生成 | `uuid` |

## 项目结构

```
lib/
├── main.dart                    # 入口，FluentApp + 主题配置
├── models/
│   └── template.dart            # Template 数据模型（id, name, content, createdAt, updatedAt）
├── pages/
│   ├── template_edit_page.dart  # 模板编辑页（默认首页）
│   └── template_list_page.dart  # 模板列表页
├── services/
│   └── template_storage.dart    # SharedPreferences 存取层
└── utils/
    └── template_engine.dart     # 变量提取（${}） + 替换引擎
```

## Template 模型

```dart
class Template {
  final String id;
  String name;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  Template({
    required this.id,
    required this.name,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
  });
}
```

## UI 约定

### 页面结构
- `ScaffoldPage` + `PageHeader` + `CommandBar`，非 `Scaffold` + `AppBar`
- 编辑页 `CommandBar.primaryItems`：复制结果、保存、模板列表
- 列表页 `PageHeader.leading`：返回按钮（`FluentIcons.back`）
- 列表页 `CommandBar.primaryItems`：新建

### Widget 映射（fluent_ui 替代 Material）

| Material | fluent_ui |
|----------|-----------|
| `MaterialApp` | `FluentApp` |
| `Scaffold` + `AppBar` | `ScaffoldPage` + `PageHeader` + `CommandBar` |
| `TextField` | `TextBox` + `InfoLabel` |
| `TextButton.icon` / `IconButton` | `CommandBarButton` |
| `AlertDialog` | `ContentDialog` |
| `SnackBar` | `InfoBar`（通过 `displayInfoBar`） |
| `CircularProgressIndicator` | `ProgressRing` |
| `FloatingActionButton` | `CommandBarButton` in Header |
| `Card` + `ListTile` | `Card` + `ListTile`（fluent 版本） |
| `MaterialPageRoute` | `FluentPageRoute` |

### TextBox 高度策略
- **模板内容**：`minLines: 1, maxLines: 5` — 自适应但有上限，防止页面间距被撑开
- **变量值输入**：`maxLines: null` — 完全自适应
- **弹窗输入**：`maxLines: 1` + `SizedBox(height: 32)` — 强制单行紧凑

### 标题栏
- 优先显示模板名称，无名称时取内容首行截断至 40 字符，再无则显示 `textemplate`
- Title `Text` 必须设置 `maxLines: 1, overflow: TextOverflow.ellipsis`

### 变量区域
- 不使用 Chip / Table / Wrap 展示变量列表
- 每个变量上方显示变量名 + 红色删除图标（`FluentIcons.delete, color: Colors.red`）
- 删除按钮使用 `GestureDetector` 包裹
- 添加变量通过 "添加" 按钮弹出 `ContentDialog`

### 结果预览区
- `Container` 包裹 `SelectableText`
- 背景色：`FluentTheme.of(context).accentColor.withAlpha(15)`
- 圆角：`BorderRadius.circular(4)`
- 内边距：`EdgeInsets.all(12)`

### 区域分隔
- 模板内容与变量区域之间、变量与结果之间使用 `Divider` 分隔
- 间距统一使用 `Gap(N)`（来自 `gap` 包），不使用 `SizedBox`

## 模板引擎

```dart
class TemplateEngine {
  static final RegExp _regex = RegExp(r'\$\{([^}]+)\}');

  static List<String> extractVariables(String content);
  static String replaceVariables(String content, Map<String, String> values);
}
```

- 正则固定为 `${变量名}`，不支持自定义
- 无 `isValidRegex` 方法，无 `customRegex` 参数

## 全局字体配置

```dart
typography: Typography.raw(
  caption:    TextStyle(fontFamily: 'Source Han Sans SC'),
  body:       TextStyle(fontFamily: 'Source Han Sans SC'),
  bodyStrong: TextStyle(fontFamily: 'Source Han Sans SC'),
  bodyLarge:  TextStyle(fontFamily: 'Source Han Sans SC'),
  subtitle:   TextStyle(fontFamily: 'Source Han Sans SC'),
  title:      TextStyle(fontFamily: 'Source Han Sans SC'),
  titleLarge: TextStyle(fontFamily: 'Source Han Sans SC'),
  display:    TextStyle(fontFamily: 'Source Han Sans SC'),
),
```

- `Typography` 使用命名构造函数 `.raw()`，不是默认构造函数
- `fluent_ui` 的 `Colors.red` 等颜色不是 `const`，搭配 `Icon` 使用时不要加 `const` 关键字

## 注意事项

- `fluent_ui` 的 `Colors` 与 Material 的 `Colors` 不同，使用 `fluent_ui` 版本
- 弹窗中 `TextBox` 需用 `SizedBox` 包裹限制高度，否则 `ContentDialog` 会分配过多空间
- `Column` 内使用 `mainAxisSize: MainAxisSize.min` 防止间距被意外拉伸
- `copyWith` 必须包含所有可变字段，避免数据丢失
- 加载模板时 `widget.template` 需同步 `name` 和 `content`
- 保存新模板时 `updateTemplate` 失败需回退 `addTemplate`
- 变量控制器生命周期：添加时 `putIfAbsent`，移除时 `dispose` + `remove`
- `_syncVariables` 负责合并提取变量与手动添加变量，清理已移除变量的控制器