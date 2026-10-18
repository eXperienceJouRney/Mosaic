//
//  PreviewData.swift
//  Mosaic
//
//  仅 DEBUG 使用：为 SwiftUI 预览与模拟器演示生成样例记录。
//  图片用渐变生成并写入 ImageStore，文件名由固定 UUID 推导，因此可重复执行。
//

#if DEBUG
import Foundation
import SwiftData
import UIKit

enum PreviewData {
    struct Sample {
        let index: Int
        let title: String
        let creator: String
        let kind: MediaKind
        let rating: Int
        let note: String
        let monthOffset: Int
        let day: Int
        let colors: [UIColor]
    }

    static let samples: [Sample] = [
        Sample(index: 1, title: "海边的卡夫卡", creator: "村上春树", kind: .book, rating: 4,
               note: "十五岁的少年拖着影子走进四国。", monthOffset: 0, day: 5,
               colors: [UIColor(red: 0.78, green: 0.65, blue: 0.47, alpha: 1), UIColor(red: 0.42, green: 0.32, blue: 0.22, alpha: 1)]),
        Sample(index: 2, title: "花样年华", creator: "王家卫", kind: .movie, rating: 5,
               note: "那些消逝了的岁月，仿佛隔着一块积着灰尘的玻璃。", monthOffset: 0, day: 5,
               colors: [UIColor(red: 0.35, green: 0.20, blue: 0.22, alpha: 1), UIColor(red: 0.12, green: 0.08, blue: 0.10, alpha: 1)]),
        Sample(index: 3, title: "挪威的森林", creator: "村上春树", kind: .book, rating: 3,
               note: "重读，感受完全不同。", monthOffset: 0, day: 8,
               colors: [UIColor(red: 0.55, green: 0.62, blue: 0.45, alpha: 1), UIColor(red: 0.24, green: 0.31, blue: 0.22, alpha: 1)]),
        Sample(index: 4, title: "星际穿越", creator: "克里斯托弗·诺兰", kind: .movie, rating: 5,
               note: "IMAX 重映。", monthOffset: 0, day: 12,
               colors: [UIColor(red: 0.30, green: 0.36, blue: 0.48, alpha: 1), UIColor(red: 0.06, green: 0.08, blue: 0.13, alpha: 1)]),
        Sample(index: 5, title: "灌篮高手", creator: "井上雄彦", kind: .comic, rating: 5,
               note: "全国大赛篇，每次看都起鸡皮疙瘩。", monthOffset: 0, day: 14,
               colors: [UIColor(red: 0.85, green: 0.48, blue: 0.28, alpha: 1), UIColor(red: 0.55, green: 0.18, blue: 0.12, alpha: 1)]),
        Sample(index: 6, title: "冀西南林路行", creator: "万能青年旅店", kind: .music, rating: 5,
               note: "在通勤路上循环了一整周。", monthOffset: 0, day: 18,
               colors: [UIColor(red: 0.55, green: 0.47, blue: 0.62, alpha: 1), UIColor(red: 0.24, green: 0.19, blue: 0.30, alpha: 1)]),
        Sample(index: 7, title: "牯岭街少年杀人事件", creator: "杨德昌", kind: .movie, rating: 5,
               note: "四个小时的夏天。", monthOffset: 0, day: 21,
               colors: [UIColor(red: 0.36, green: 0.42, blue: 0.33, alpha: 1), UIColor(red: 0.12, green: 0.15, blue: 0.11, alpha: 1)]),
        Sample(index: 8, title: "树上的男爵", creator: "伊塔洛·卡尔维诺", kind: .book, rating: 5,
               note: "为了抵抗，先要离开地面。", monthOffset: 0, day: 27,
               colors: [UIColor(red: 0.62, green: 0.70, blue: 0.55, alpha: 1), UIColor(red: 0.26, green: 0.34, blue: 0.20, alpha: 1)]),
        Sample(index: 9, title: "OPUS", creator: "今敏", kind: .comic, rating: 4,
               note: "现实与分镜互相穿透。", monthOffset: -1, day: 6,
               colors: [UIColor(red: 0.80, green: 0.62, blue: 0.42, alpha: 1), UIColor(red: 0.45, green: 0.24, blue: 0.18, alpha: 1)]),
        Sample(index: 10, title: "蓝", creator: "德里克·贾曼", kind: .movie, rating: 4,
               note: "只有蓝色，和声音。", monthOffset: -1, day: 9,
               colors: [UIColor(red: 0.16, green: 0.28, blue: 0.62, alpha: 1), UIColor(red: 0.04, green: 0.07, blue: 0.18, alpha: 1)]),
        Sample(index: 11, title: "async", creator: "坂本龙一", kind: .music, rating: 4,
               note: "雨天，音量调小一点。", monthOffset: -1, day: 14,
               colors: [UIColor(red: 0.40, green: 0.44, blue: 0.50, alpha: 1), UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)]),
        Sample(index: 12, title: "局部", creator: "陈丹青", kind: .other, rating: 3,
               note: "断断续续看完。", monthOffset: -1, day: 22,
               colors: [UIColor(red: 0.72, green: 0.66, blue: 0.55, alpha: 1), UIColor(red: 0.32, green: 0.28, blue: 0.22, alpha: 1)]),
        Sample(index: 13, title: "Design Matters", creator: "Debbie Millman", kind: .podcast, rating: 4,
               note: "在跑步机上听完的一期。", monthOffset: 0, day: 12,
               colors: [UIColor(red: 0.58, green: 0.60, blue: 0.64, alpha: 1), UIColor(red: 0.24, green: 0.26, blue: 0.30, alpha: 1)]),
        Sample(index: 14, title: "风之旅人", creator: "thatgamecompany", kind: .game, rating: 5,
               note: "没有一个字的旅程。", monthOffset: 0, day: 12,
               colors: [UIColor(red: 0.86, green: 0.72, blue: 0.52, alpha: 1), UIColor(red: 0.52, green: 0.38, blue: 0.24, alpha: 1)]),
        Sample(index: 15, title: "观看之道", creator: "约翰·伯格", kind: .book, rating: 5,
               note: "看的方式本身就是一种权力。", monthOffset: 0, day: 12,
               colors: [UIColor(red: 0.68, green: 0.68, blue: 0.62, alpha: 1), UIColor(red: 0.30, green: 0.30, blue: 0.26, alpha: 1)]),
        Sample(index: 16, title: "Blue", creator: "Joni Mitchell", kind: .music, rating: 5,
               note: "冬天必听。", monthOffset: 0, day: 12,
               colors: [UIColor(red: 0.44, green: 0.56, blue: 0.72, alpha: 1), UIColor(red: 0.14, green: 0.20, blue: 0.34, alpha: 1)]),
        Sample(index: 17, title: "忽左忽右", creator: "程衍樑", kind: .podcast, rating: 4,
               note: "通勤节目。", monthOffset: -1, day: 3,
               colors: [UIColor(red: 0.62, green: 0.56, blue: 0.50, alpha: 1), UIColor(red: 0.26, green: 0.22, blue: 0.19, alpha: 1)]),
        Sample(index: 18, title: "Baba Is You", creator: "Hempuli", kind: .game, rating: 4,
               note: "规则本身才是关卡。", monthOffset: -1, day: 18,
               colors: [UIColor(red: 0.56, green: 0.66, blue: 0.50, alpha: 1), UIColor(red: 0.20, green: 0.28, blue: 0.18, alpha: 1)]),

        // 往后两个月：用来确认切换月份后图片、筛选与日期位置一起更新。
        Sample(index: 19, title: "一一", creator: "杨德昌", kind: .movie, rating: 5,
               note: "电影发明以后，人类的生命至少延长了三倍。", monthOffset: 1, day: 3,
               colors: [UIColor(red: 0.58, green: 0.54, blue: 0.44, alpha: 1), UIColor(red: 0.22, green: 0.20, blue: 0.16, alpha: 1)]),
        Sample(index: 20, title: "百年孤独", creator: "加西亚·马尔克斯", kind: .book, rating: 5,
               note: "多年以后，面对行刑队……", monthOffset: 1, day: 11,
               colors: [UIColor(red: 0.78, green: 0.66, blue: 0.32, alpha: 1), UIColor(red: 0.40, green: 0.30, blue: 0.10, alpha: 1)]),
        Sample(index: 21, title: "随机波动", creator: "适野 / 建国 / 之琪", kind: .podcast, rating: 4,
               note: "关于女性、文化与当下的讨论。", monthOffset: 1, day: 21,
               colors: [UIColor(red: 0.66, green: 0.48, blue: 0.52, alpha: 1), UIColor(red: 0.30, green: 0.16, blue: 0.20, alpha: 1)]),
        Sample(index: 22, title: "塞尔达传说：旷野之息", creator: "任天堂", kind: .game, rating: 5,
               note: "看到山就想爬。", monthOffset: 1, day: 26,
               colors: [UIColor(red: 0.44, green: 0.64, blue: 0.48, alpha: 1), UIColor(red: 0.12, green: 0.26, blue: 0.18, alpha: 1)]),
        Sample(index: 23, title: "范特西", creator: "周杰伦", kind: .music, rating: 5,
               note: "二十多年后听还是不过时。", monthOffset: -2, day: 7,
               colors: [UIColor(red: 0.62, green: 0.36, blue: 0.30, alpha: 1), UIColor(red: 0.26, green: 0.10, blue: 0.10, alpha: 1)]),
        Sample(index: 24, title: "电锯人", creator: "藤本树", kind: .comic, rating: 4,
               note: "荒诞、暴力，又意外地温柔。", monthOffset: -2, day: 17,
               colors: [UIColor(red: 0.72, green: 0.30, blue: 0.28, alpha: 1), UIColor(red: 0.30, green: 0.08, blue: 0.08, alpha: 1)]),
        Sample(index: 25, title: "但是还有书籍", creator: "罗颖鸾", kind: .other, rating: 4,
               note: "关于编辑、译者与旧书店。", monthOffset: -2, day: 28,
               colors: [UIColor(red: 0.70, green: 0.64, blue: 0.50, alpha: 1), UIColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1)]),
        Sample(index: 26, title: "春光乍泄", creator: "王家卫", kind: .movie, rating: 5,
               note: "不如我们从头来过。", monthOffset: -3, day: 9,
               colors: [UIColor(red: 0.24, green: 0.40, blue: 0.40, alpha: 1), UIColor(red: 0.06, green: 0.14, blue: 0.14, alpha: 1)]),
        Sample(index: 27, title: "献给阿尔吉侬的花束", creator: "丹尼尔·凯斯", kind: .book, rating: 4,
               note: "智力改变以后，人还是同一个人吗？", monthOffset: -3, day: 23,
               colors: [UIColor(red: 0.66, green: 0.70, blue: 0.56, alpha: 1), UIColor(red: 0.28, green: 0.32, blue: 0.20, alpha: 1)]),
        Sample(index: 28, title: "去月球", creator: "Kan Gao", kind: .game, rating: 5,
               note: "一个关于记忆与遗憾的故事。", monthOffset: -3, day: 28,
               colors: [UIColor(red: 0.36, green: 0.42, blue: 0.60, alpha: 1), UIColor(red: 0.10, green: 0.12, blue: 0.24, alpha: 1)]),
        Sample(index: 29, title: "Tomorrow's Modern Boxes", creator: "Thom Yorke", kind: .music, rating: 4,
               note: "冷冽的电子纹理。", monthOffset: 2, day: 5,
               colors: [UIColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1), UIColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 1)]),
        Sample(index: 30, title: "一天世界", creator: "李如一", kind: .podcast, rating: 4,
               note: "关于技术、媒介与品味的节目。", monthOffset: 2, day: 19,
               colors: [UIColor(red: 0.52, green: 0.52, blue: 0.46, alpha: 1), UIColor(red: 0.20, green: 0.20, blue: 0.17, alpha: 1)]),
        Sample(index: 31, title: "迷宫饭", creator: "九井谅子", kind: .comic, rating: 5,
               note: "把迷宫里的魔物做成料理。", monthOffset: 2, day: 24,
               colors: [UIColor(red: 0.76, green: 0.62, blue: 0.36, alpha: 1), UIColor(red: 0.34, green: 0.24, blue: 0.10, alpha: 1)]),
    ]

    static func populate(_ context: ModelContext) {
        for sample in samples {
            let identifier = stableID(sample.index)
            let fileName = ImageStore.shared.fileName(for: identifier)

            var pixelWidth: Double = 0
            var pixelHeight: Double = 0
            if !ImageStore.shared.contains(named: fileName),
               let stored = try? ImageStore.shared.save(gradientImage(colors: sample.colors), identifier: identifier) {
                pixelWidth = stored.pixelWidth
                pixelHeight = stored.pixelHeight
            }

            let item = MediaItem(
                title: sample.title,
                creator: sample.creator,
                kind: sample.kind,
                rating: sample.rating,
                note: sample.note,
                recordDate: recordDate(for: sample),
                imageFileName: fileName,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                id: identifier
            )
            context.insert(item)
        }
    }

    // MARK: - 辅助

    static func stableID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "0000A000-0000-4000-8000-%012d", index)) ?? UUID()
    }

    static func recordDate(for sample: Sample) -> Date {
        let month = MosaicCalendar.addMonths(sample.monthOffset, to: .now)
        return MosaicCalendar.addDays(sample.day - 1, to: month)
    }

    static func gradientImage(colors: [UIColor], size: CGSize = CGSize(width: 900, height: 1200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgColors = colors.map(\.cgColor) as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: cgColors,
                locations: [0, 1]
            ) else { return }
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }
}
#endif
