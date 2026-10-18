# Mosaic · App Icon

图标用代码画出来（`Tools/generate_app_icons.py`），不依赖手工位图，颜色全部取自
`Mosaic/Support/Theme.swift` 的纸感 / 墨色 token，改动可复现。

## 设计

- **主图（bento）**：一块温润的纸底，上面是四块不等大的「照片」拼贴 —— 正好对应日历里
  每天显示 2×2 缩略图的那套语言。暖杏色作为视觉主角，深墨色方块是品牌锚点，沙色和
  橄榄绿做安静的配重。每块带一条柔和的地平线（对应参考稿里 `--land` 的绿丘），远看
  像照片，近看只是色块。
- **纸感**：底色 `#F7F6F2`，顶部一线暖光，方块间留 28px 纸缝，下方一层极轻的印刷投影，
  最后铺一层 4×4 的纸纤维颗粒（不放大看不出，只是让渐变更像纸）。
- **安全区**：拼贴区 760×760、四边留 132px，圆角交给系统裁切（1080/1024 不预裁）。
- **三种外观**：亮色 / 深色 / 着色（grayscale + alpha，交给系统 tint）。

主色：
`paper #F7F6F2` `ink #242522` `apricot #E3B087→#CA8863` `sand #E8D5B8→#CBAD82`
`olive #A9AE8E→#768262` `dusty #AFBDC4→#7E929E`

## 文件

| 路径 | 说明 |
| --- | --- |
| `Mosaic/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | 亮色 1024 母版（已接入 app） |
| `…/AppIcon-Dark.png` / `…/AppIcon-Tinted.png` | 深色 / 着色外观 |
| `Design/AppIcon/icon-sheet.png` | 尺寸与外观对照表 |
| `Design/AppIcon/icon-home-screen.png` | 亮/暗壁纸预览 |
| `Design/AppIcon/master/*.png` | 各备选方案的 1024 母版 |

## 重新生成 / 换方案

```bash
PY=/Users/ray/.dsh/dsh-runtimes/dsh-primary-runtime/dependencies/python/bin/python3
$PY Tools/generate_app_icons.py --all                       # 生成全部备选到 master/
$PY Tools/generate_app_icons.py --concept bento --install   # 装进 asset catalog
$PY Tools/make_icon_preview.py                              # 重画对照表
```

备选：`monogram`（字母 M 拼贴）、`bento-cool`（冷色块）、`edge`（满版拼贴，四角交给系统裁）。

## 校验

```bash
xcrun actool Mosaic/Assets.xcassets --compile /tmp/icons --platform iphoneos \
  --minimum-deployment-target 17.0 --app-icon AppIcon --output-partial-info-plist /tmp/icons/p.plist
```

应无 warning，输出 `AppIcon60x60@2x.png` 与 `Assets.car`；`assetutil --info` 里能看到
`UIAppearanceDark` 与 `ISAppearanceTintable` 两套外观。
