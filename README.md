# Mosaic

> 把看过的、读过的、听过的，拼成一张日历。

Mosaic 是一个极简的「书影音」记录 App：看过的电影、读过的书、听过的专辑、追过的播客、玩过的游戏，都能带着一张封面和几句感受，落回到它发生的那一天。首页不是信息流，也不是排行榜，而是一面**日历画廊**——每一天的格子里铺着当天的封面拼贴，一年下来就是一张由内容拼成的马赛克。

![Mosaic 界面展板](<极简日历媒体记录应用界面展板.png>)

---

## 功能

### 日历画廊

- 七列月历，每格按当天记录数量自动排版：1 张铺满、2 张并列、3–4 张 2×2 拼贴，超过 4 张显示 `+N`
- 空日期也保留 4:3 图片区，整行永远对齐；非本月日期淡出显示
- 点格子进入当天记录，点封面看完整详情
- 分类筛选贯通画廊与时间轴，新增自定义分类即时生效

### 时间轴

- 以「年份」为唯一标题，按月分组回看收藏
- 三条互不干扰的筛选：年份 / 分类 / 时间范围（全部、近 3 月、近 1 月）
- 每条记录带一个动作标签：`WATCHED` / `READ` / `LISTENED` / `SAVED`

### 记录

- 一张图 + 标题、创作者、分类、标签、个人感受、记录日期
- 表单文案随分类变化：电影叫「片名 / 导演」，书籍叫「书名 / 作者」，音乐叫「专辑或单曲 / 艺术家」
- 标签支持中英文逗号、顿号、`#` 分隔，自动去重去空白
- 编辑复用同一张表单，取消不改动原记录；删除走系统确认弹窗，连同图片一并清理

### 分类

- 内置 7 类：电影、书籍、漫画、音乐、播客、游戏、其他
- 可新建自定义分类；分类 id 以字符串落库，删除分类时记录保留，回退显示为「其他」

---

## 设计

整套视觉对齐 `mosaic_calendar_gallery_reference.html`：纸感底色 `#F7F6F2`、墨色正文 `#242522`、发丝分隔线 `#E9E7E0`。没有 App 标题、Logo 或欢迎语——**画廊本身就是首屏**。

所有颜色、间距、字号都收敛在 `Mosaic/Support/Theme.swift` 的 token 里，视图里不出现魔法数字；应用图标也由代码绘制（`Tools/generate_app_icons.py`），配色取自同一套 token，可复现、可替换。

| 亮色 | 深色 | 着色 |
| --- | --- | --- |
| `AppIcon.png` | `AppIcon-Dark.png` | `AppIcon-Tinted.png` |

改图标或重新生成：

```bash
python3 -m pip install Pillow            # 仅图标脚本需要
python3 Tools/generate_app_icons.py --concept bento --install
python3 Tools/make_icon_preview.py
```

---

## 技术栈

| 层面 | 选型 |
| --- | --- |
| UI | SwiftUI，iOS 17.0+，iPhone |
| 数据 | SwiftData（`@Model` + `@Query`） |
| 图片 | PhotosUI `PhotosPicker`、ImageIO 降采样、`NSCache` 缩略图缓存 |
| 测试 | Swift Testing（单元）、XCUITest（界面） |
| 依赖 | 无第三方依赖 |

**本地优先**：没有账号、没有网络请求，记录写在 Application Support 的 SwiftData 库里，原图随 iCloud 备份。

---

## 项目结构

```
Mosaic/
├── Models/          MediaItem、RecordDraft、MediaKind、MediaCategory、MediaTags
├── Calendar/        纯逻辑：MonthGrid、DayIndex、TimelineFeed
├── Persistence/     MosaicContainer、RecordStore、ImageStore、MediaCategoryStore
├── Views/
│   ├── Gallery/     日历画廊：月标题、筛选栏、日格、月份选择器
│   ├── Timeline/    时间轴：年份标题、范围切换、条目行
│   ├── DayRecords/  当天列表与作品详情
│   ├── AddRecord/   添加 / 编辑表单、图片选择、分类选择
│   └── Components/  缩略图、底部导航、页面标题、按钮样式
├── Support/         Theme 视觉 token、MosaicCalendar、PreviewData
└── MosaicApp.swift  入口与容器装配

MosaicTests/         Swift Testing 单元测试（日历、分组、筛选、草稿、持久化）
MosaicUITests/       XCUITest 界面测试（新增、详情、分类、时间轴、画廊）
Design/AppIcon/      图标母版与预览
Tools/               图标生成脚本
```

两条关键约束：

1. **纯逻辑与视图分离**。`MonthGrid`、`DayIndex`、`TimelineFeed` 不依赖 SwiftUI / SwiftData，全部由单元测试覆盖。
2. **数据一致性收敛到 `RecordStore`**。图片先落盘再存模型，失败回滚并清理；换图用新文件名，成功后才删旧图；删除记录时一并删除原图与缩略图。View 只负责收集草稿。

---

## 快速开始

要求：Xcode 16+（单元测试使用 Swift Testing）、iOS 17.0 模拟器或真机。

```bash
git clone git@github.com:eXperienceJouRney/Mosaic.git
cd Mosaic
open Mosaic.xcodeproj
```

选择 `Mosaic` scheme 与任一 iOS 模拟器运行即可，首次启动为空画廊。

命令行构建与测试：

```bash
# 构建
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic \
  -destination 'generic/platform=iOS Simulator' build

# 全部测试
xcodebuild -project Mosaic.xcodeproj -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### 调试用启动参数

仅为调试提供，用来把界面拉到某个已知状态（除 `-resetMediaCategories` 外均只在 DEBUG 生效）：

| 参数 | 作用 |
| --- | --- |
| `-usePreviewContainer` | 内存库 + 样例数据，每次启动都是干净的 |
| `-useEmptyStore` | 干净的内存库，便于断言新增条数 |
| `-usePersistentTestStore` | 真实磁盘库，验证重启后数据仍在 |
| `-resetPersistentTestStore` | 配合上一条，启动前清空磁盘库 |
| `-seedSampleData` | 往持久库灌入样例数据 |
| `-resetMediaCategories` | 自定义分类恢复为内置 7 类 |

---

## 测试

- **单元测试** `MosaicTests/`：日历归一化与月份网格、按天分桶、时间轴分组与筛选、草稿规范化、持久化与编辑回滚
- **界面测试** `MosaicUITests/`：日历画廊、当天列表、添加记录、作品详情、分类管理、时间轴

```bash
# 只跑单元测试
xcodebuild test -project Mosaic.xcodeproj -scheme Mosaic \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:MosaicTests
```

---

## 说明

- 应用界面与注释以中文为主，Markdown 文档同理。
- `mosaic_calendar_gallery_reference.html`、`mosaic_timeline.html` 是设计参考稿，不参与编译。
- 仓库暂未附开源协议；如需分发请先补充 `LICENSE`。
