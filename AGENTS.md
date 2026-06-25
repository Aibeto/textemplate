# AGENTS.md

## 项目概览

**textemplate** — 文本模板生成器，基于 `fluent_ui` 构建的 Windows 桌面应用。用户定义含 `${变量}` 占位符的模板，填写变量值后实时生成最终文本并一键复制。

## 技术栈

| 层 | 选型 |
|---|------|
| UI 框架 | `fluent_ui: ^4.10.1`（Win11 风格） |
| 间距 | `gap: ^3.0.1`（`Gap` 替代 `SizedBox`） |
| 字体 | `Maple Mono NF CN`（内置等宽字体），通过 `FluentThemeData.fontFamily` 配置，完整字重 100-800 + Italic 变体 |
| 持久化 | `shared_preferences`（JSON 序列化模板列表） |
| ID 生成 | `uuid` |

## 项目结构

```
lib/
├── main.dart                    # 入口，FluentApp + 主题 + 自定义侧边栏导航（IndexedStack）
├── models/
│   └── template.dart            # Template 数据模型（id, name, content, createdAt, updatedAt）
├── pages/
│   ├── template_edit_page.dart  # 模板编辑页（导航栏默认页）
│   └── template_list_page.dart  # 模板列表页（导航栏第二页）
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
- 自定义 `Row` 布局：左侧 48px 侧边栏（`_NavIcon`）+ 右侧 `Stack` + `AnimatedOpacity` 内容区
- 使用 `Stack` + `AnimatedOpacity` 实现页面淡入淡出切换，同时保持所有页面存活
- 使用 `ValueNotifier<int>` 版本号机制在编辑页保存后通知列表页刷新
- 列表页选中模板后自动切换到编辑页，通过 `HomePage` 的 `onTemplateSelected` 回调和 `ValueKey` 重建
- 编辑页 `CommandBar.primaryItems`：复制结果、保存
- 列表页 `CommandBar.primaryItems`：新建
- 启动时通过 `TemplateStorage.getLastTemplateId()` 加载上次编辑的模板，显示欢迎 InfoBar

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
- 每个变量上方显示变量名（16px 粗体）+ 红色删除图标（`FluentIcons.delete, size: 16, color: Colors.red`）
- 删除按钮使用 `GestureDetector` 包裹
- 添加变量通过 "添加" 按钮弹出 `ContentDialog`

### 结果预览区
- `Container` 包裹 `SelectableText`
- 背景色：`FluentTheme.of(context).accentColor.withAlpha(15)`
- 圆角：`BorderRadius.circular(4)`
- 内边距：`EdgeInsets.all(12)`

### 区域分隔
- 模板内容与变量区域之间、变量与结果之间使用 `Divider` 分隔
- 区域间间距统一使用 `Gap(16)`，区域内元素间距 `Gap(8)`

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

直接在 `FluentThemeData` 构造函数中传入 `fontFamily`，内部会自动基于 `Typography.fromBrightness()` 创建完整样式（含正确的 `fontSize`、`fontWeight`、`color`、`height`），然后通过 `apply(fontFamily:)` 附加字体：

```dart
FluentThemeData(
  // fontFamily 通过 Typography.apply(fontFamily:) 附加到默认字体系列
  fontFamily: 'Maple Mono NF CN',
  // ...
)
```

**不要**使用 `Typography.raw()` 手动设置 fontFamily，那样会替换掉所有默认样式属性（尺寸、粗细、颜色、行高），导致字体颜色错误。

## 注意事项

- `fluent_ui` 的 `Colors` 与 Material 的 `Colors` 不同，使用 `fluent_ui` 版本
- `fluent_ui` 的 `Colors.red` 等颜色不是 `const`，搭配 `Icon` 使用时不要加 `const` 关键字
- 弹窗中 `TextBox` 需用 `SizedBox` 包裹限制高度，否则 `ContentDialog` 会分配过多空间
- `Column` 内使用 `mainAxisSize: MainAxisSize.min` 防止间距被意外拉伸
- `copyWith` 必须包含所有可变字段，避免数据丢失
- 保存新模板时 `updateTemplate` 失败需回退 `addTemplate`
- 变量控制器生命周期：添加时 `putIfAbsent`，移除时 `dispose` + `remove`
- `_syncVariables` 负责合并提取变量与手动添加变量，清理已移除变量的控制器