//
//  Theme.swift
//  Mosaic
//
//  与 mosaic_calendar_gallery_reference.html 对齐的视觉 token。
//  所有颜色 / 尺寸 / 字号都从这里取，视图里不出现魔法数字。
//

import SwiftUI

enum Theme {
    enum Palette {
        /// 纸感背景 #F7F6F2
        static let paper = Color(hex: 0xF7F6F2)
        /// 卡片 / 面板面 #FFFEFA
        static let surface = Color(hex: 0xFFFEFA)
        /// 墨色正文 #242522
        static let ink = Color(hex: 0x242522)
        /// 次要文字 #8D8D85
        static let muted = Color(hex: 0x8D8D85)
        /// 发丝分隔线 #E9E7E0
        static let hairline = Color(hex: 0xE9E7E0)
        /// 柔面 #EFEEE8
        static let soft = Color(hex: 0xEFEEE8)
        /// 深色强调 #22231F
        static let accent = Color(hex: 0x22231F)
        /// 深色底上的文字
        static let onAccent = Color.white

        // 日历
        static let dayNumber = Color(hex: 0x7E7F77)
        static let weekdayLabel = Color(hex: 0x8E8E86)
        static let pressBackground = Color(hex: 0xEEEDE7)
        static let pressBorder = Color(hex: 0xD9D7CF)
        static let thumbPlaceholder = Color(hex: 0xD7D1C4)

        // 筛选
        static let filterText = Color(hex: 0x66675F)
        static let filterBorder = Color(hex: 0xE5E3DC)

        // 图标按钮
        static let iconButton = Color(hex: 0x393A35)

        // 表单
        static let fieldPlaceholder = Color(hex: 0xB5B3AB)
        static let fieldBackground = Color(hex: 0xF2F0EA)

        // 删除等破坏性操作
        static let danger = Color(hex: 0xA6462F)

        // 详情页标签
        static let tagBorder = Color(hex: 0xE5E3DC)

        // 时间轴
        /// 贯穿时间轴的竖线 #DFDCD3
        static let timelineLine = Color(hex: 0xDFDCD3)
        /// 时间轴节点 #B4B0A4
        static let timelineDot = Color(hex: 0xB4B0A4)
        /// 月份 / 分类这类小字 #85837A
        static let timelineMeta = Color(hex: 0x85837A)
        /// 感受正文 #626159
        static let secondaryInk = Color(hex: 0x626159)
        /// 年份选择 #77766E
        static let yearText = Color(hex: 0x77766E)
        /// 时间范围分段控件底 #EEECE5
        static let segmentBackground = Color(hex: 0xEEECE5)
        /// 未选中的分段文字 #85837A
        static let segmentText = Color(hex: 0x85837A)

        // 底部导航
        static let tabInactive = Color(hex: 0x9B998F)
    }

    enum Spacing {
        static let screenPadding: CGFloat = 14
        static let appTop: CGFloat = 10

        static let monthBarTop: CGFloat = 3
        static let monthBarBottom: CGFloat = 16
        static let filterBottom: CGFloat = 17
        static let weekdayBottom: CGFloat = 8
        static let dayNumberHeight: CGFloat = 18

        /// FAB 距安全区底部的距离。参考稿是相对屏幕底 31pt（含 Home Indicator），
        /// iOS 上按安全区收缩，避免压到指示条。
        static let fabBottom: CGFloat = 8
        static let fabTrailing: CGFloat = 20
    }

    enum Radius {
        static let cell: CGFloat = 5
        static let thumb: CGFloat = 2
        static let card: CGFloat = 12
        static let sheet: CGFloat = 24
        static let field: CGFloat = 10
    }

    enum Grid {
        static let columnCount = 7
        static let spacing: CGFloat = 4
        static let collageSpacing: CGFloat = 2
        /// 图片默认竖版 4:3（宽 : 高 = 3 : 4），格子高度 = 日号 18pt + 图片高度。
        static let photoAspectRatio: CGFloat = 3.0 / 4.0
    }

    /// 分类筛选栏与「新建分类」面板。
    enum Filter {
        static let pillSpacing: CGFloat = 6
        static let pillHorizontal: CGFloat = 12
        static let pillVertical: CGFloat = 7
        static let deleteBadgeSpacing: CGFloat = 4
        static let deleteBadgeSize: CGFloat = 10
        static let addIconSize: CGFloat = 9
        static let addIconSpacing: CGFloat = 3
        /// 编辑态用虚线描边，和普通胶囊区分开。
        static let editDash: [CGFloat] = [3, 2]
        static let editAnimationDuration: Double = 0.16
        static let longPressDuration: Double = 0.45
        /// 分类标题上限，避免胶囊过长挤占整行。
        static let maxTitleLength: Int = 12
        /// 编辑态行尾「新分类」按钮的滚动锚点。
        static let addPillID = "filter-add-category"

        static let sheetHeight: CGFloat = 252
        static let sheetHorizontal: CGFloat = 20
        static let sheetTop: CGFloat = 18
        static let sheetBottom: CGFloat = 16
        static let sheetSectionSpacing: CGFloat = 14
        static let sheetFieldPadding: CGFloat = 10
        static let sheetActionSpacing: CGFloat = 12
        static let sheetTitleSpacing: CGFloat = 4
    }

    enum Tracking {
        static let month: CGFloat = -1.4
        static let detailTitle: CGFloat = -0.9
        static let timelineEntryTitle: CGFloat = -0.4
        /// 10pt 以下的小字需要正字距才不糊。
        static let timelineLabel: CGFloat = 0.9
        static let timelineMonth: CGFloat = 1.3
    }

    /// 月份选择面板的尺寸，全部按 3 列 × 4 行推算，保持轻量。
    enum Picker {
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 14
        static let topPadding: CGFloat = 20
        static let bottomPadding: CGFloat = 10
        static let yearBarHeight: CGFloat = 32
        static let monthHeight: CGFloat = 42
        static let sheetHeight: CGFloat = 336
    }

    /// 当天记录列表。
    enum DayList {
        static let columns = 2
        static let spacing: CGFloat = 12
        static let cardCorner: CGFloat = 12
        static let artHeight: CGFloat = 150
        static let copyPadding: CGFloat = 10
        static let topPadding: CGFloat = 4
        static let bottomPadding: CGFloat = 40
        static let headerBottom: CGFloat = 14
    }

    /// 当两条以上记录共用同一个返回按钮的顶栏。
    enum ScreenHeader {
        static let backHitSize: CGFloat = 40
        static let spacing: CGFloat = 10
        static let bottom: CGFloat = 14
        static let subtitleTop: CGFloat = 2
    }

    /// 时间轴页。尺寸按 mosaic_timeline.html 的 420pt 版心折算，
    /// 左列是日期，右侧是「文字 + 封面」，中缝一条贯穿全页的竖线。
    /// 标题区与画廊共用 Spacing.monthBarTop / monthBarBottom。
    enum Timeline {
        static let rangeTop: CGFloat = 13
        static let rangeBottom: CGFloat = 20
        static let segmentPadding: CGFloat = 3
        static let segmentGap: CGFloat = 3
        static let segmentHorizontal: CGFloat = 9
        static let segmentVertical: CGFloat = 6

        static let dateColumnWidth: CGFloat = 40
        static let columnGap: CGFloat = 17
        static let dateTop: CGFloat = 4
        static let weekdayTop: CGFloat = 5

        /// 竖线 x 位置（相对版心左侧）与上下留白。
        static let lineX: CGFloat = 39
        static let lineTop: CGFloat = 4
        static let lineBottom: CGFloat = 15
        /// 节点圆心（相对整行左上角）。
        static let dotCenterX: CGFloat = 39.5
        static let dotCenterY: CGFloat = 12.5
        static let dotSize: CGFloat = 7
        /// 节点外的纸色圆环，让竖线在节点处断开。
        static let dotRingSize: CGFloat = 15

        static let monthBottom: CGFloat = 17
        static let entryBottom: CGFloat = 25
        static let metaToMain: CGFloat = 9
        static let titleToCreator: CGFloat = 5
        static let creatorToNote: CGFloat = 9

        static let copyToCover: CGFloat = 12
        static let coverWidth: CGFloat = 112
        static let coverHeight: CGFloat = 125
        static let coverCorner: CGFloat = 5

        static let topPadding: CGFloat = 2
        /// 留出右下角添加按钮的高度，最后一条记录不会被压住。
        static let bottomPadding: CGFloat = 76
        static let emptyTop: CGFloat = 10
    }

    /// 底部导航。与时间轴参考稿一样，只有 Gallery / Timeline 两项。
    enum TabBar {
        static let top: CGFloat = 8
        static let bottom: CGFloat = 4
        static let iconSize: CGFloat = 15
        static let iconLabelGap: CGFloat = 7
        static let hitHeight: CGFloat = 38
        static let hairlineHeight: CGFloat = 1
    }

    /// 作品详情页。
    enum Detail {
        static let photoHeight: CGFloat = 380
        static let photoCorner: CGFloat = 12
        static let contentPadding: CGFloat = 18
        static let contentTop: CGFloat = 16
        static let metaSpacing: CGFloat = 8
        static let titleSpacing: CGFloat = 5
        static let sectionSpacing: CGFloat = 14
        static let noteLineSpacing: CGFloat = 5
        static let actionTop: CGFloat = 26
        static let actionSpacing: CGFloat = 12
        static let tagSpacing: CGFloat = 6
    }

    /// 添加记录页的尺寸。只保留让表单呼吸所需的最小间距。
    enum Form {
        static let horizontalPadding: CGFloat = 20
        static let topPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 40
        static let sectionSpacing: CGFloat = 22
        static let fieldSpacing: CGFloat = 7

        static let topBarVertical: CGFloat = 6
        static let actionHitHeight: CGFloat = 32

        static let saveHorizontal: CGFloat = 16
        static let saveVertical: CGFloat = 7
        static let saveMinWidth: CGFloat = 54

        static let photoHeight: CGFloat = 156
        static let photoCorner: CGFloat = 14
        static let photoIconSize: CGFloat = 20
        static let photoRemoveSize: CGFloat = 24
        static let photoRemovePadding: CGFloat = 8

        static let rowVertical: CGFloat = 13
        static let rowLabelWidth: CGFloat = 56

        static let noteHeight: CGFloat = 96
        static let notePadding: CGFloat = 10
        static let noteTextInset: CGFloat = 5
    }

    enum Typography {
        static let month = Font.system(size: 25, weight: .regular)
        static let iconButton = Font.system(size: 21, weight: .regular)
        static let weekday = Font.system(size: 9, weight: .regular)
        static let filter = Font.system(size: 11, weight: .regular)
        static let dayNumber = Font.system(size: 9, weight: .regular)
        static let dayNumberToday = Font.system(size: 9, weight: .heavy)
        static let moreCount = Font.system(size: 8, weight: .medium)
        static let fab = Font.system(size: 26, weight: .light)
        static let cardTitle = Font.system(size: 12, weight: .semibold)
        static let cardMeta = Font.system(size: 10, weight: .regular)

        // 时间轴
        static let timelineMonth = Font.system(size: 10, weight: .regular)
        static let timelineDay = Font.system(size: 17, weight: .regular)
        static let timelineWeekday = Font.system(size: 9, weight: .regular)
        static let timelineMeta = Font.system(size: 9, weight: .regular)
        static let timelineEntryTitle = Font.system(size: 16, weight: .medium)
        static let timelineCreator = Font.system(size: 11, weight: .regular)
        static let timelineNote = Font.system(size: 11, weight: .regular)
        static let timelineRangeLabel = Font.system(size: 9, weight: .regular)
        static let timelineSegment = Font.system(size: 10, weight: .regular)
        static let timelineEmpty = Font.system(size: 12, weight: .regular)

        // 分类管理
        static let sheetTitle = Font.system(size: 16, weight: .semibold)

        // 底部导航
        static let tabLabel = Font.system(size: 11, weight: .regular)
        static let tabLabelSelected = Font.system(size: 11, weight: .semibold)

        // 月份选择器
        static let pickerYear = Font.system(size: 17, weight: .semibold)
        static let pickerMonth = Font.system(size: 12, weight: .regular)
        static let pickerMonthSelected = Font.system(size: 12, weight: .semibold)
        static let pickerAction = Font.system(size: 12, weight: .regular)

        // 添加记录表单
        static let formPageTitle = Font.system(size: 13, weight: .semibold)
        static let formAction = Font.system(size: 15, weight: .regular)
        static let formActionEmphasis = Font.system(size: 15, weight: .medium)
        static let formTitleField = Font.system(size: 21, weight: .regular)
        static let formField = Font.system(size: 15, weight: .regular)
        static let formLabel = Font.system(size: 11, weight: .regular)
        static let formPhotoPrompt = Font.system(size: 12, weight: .regular)

        // 当天记录 / 详情页
        static let screenTitle = Font.system(size: 15, weight: .semibold)
        static let screenSubtitle = Font.system(size: 10, weight: .regular)
        static let backIcon = Font.system(size: 17, weight: .regular)
        static let detailTitle = Font.system(size: 24, weight: .regular)
        static let detailMeta = Font.system(size: 10, weight: .regular)
        static let detailCreator = Font.system(size: 12, weight: .regular)
        static let detailBody = Font.system(size: 14, weight: .regular)
        static let tag = Font.system(size: 10, weight: .regular)
        static let detailAction = Font.system(size: 15, weight: .medium)
        static let deleteAction = Font.system(size: 13, weight: .regular)
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
