//
//  MediaKind.swift
//  Mosaic
//
//  记录类型。顺序按参考稿的筛选栏排列：
//  电影 / 书籍 / 漫画 / 音乐 / 播客 / 游戏 / 其他（「全部」由筛选状态表示）。
//

import Foundation

enum MediaKind: String, CaseIterable, Identifiable, Codable {
    case movie
    case book
    case comic
    case music
    case podcast
    case game
    case other

    var id: String { rawValue }

    /// 筛选栏的展示顺序。
    static let filterOrder: [MediaKind] = [.movie, .book, .comic, .music, .podcast, .game, .other]

    var title: String {
        switch self {
        case .movie: return "电影"
        case .book: return "书籍"
        case .comic: return "漫画"
        case .music: return "音乐"
        case .podcast: return "播客"
        case .game: return "游戏"
        case .other: return "其他"
        }
    }

    /// 无图片时的占位符号。
    var symbolName: String {
        switch self {
        case .movie: return "film"
        case .book: return "book.closed"
        case .comic: return "book.pages"
        case .music: return "music.note"
        case .podcast: return "mic"
        case .game: return "gamecontroller"
        case .other: return "sparkles"
        }
    }

    /// 时间轴每条记录右上角的小字：用「做过什么」代替重复的分类词。
    /// 与参考稿一致的三个动词之外的分类统一落到 SAVED。
    var timelineActionLabel: String {
        switch self {
        case .movie: return "WATCHED"
        case .book, .comic: return "READ"
        case .music, .podcast: return "LISTENED"
        case .game, .other: return "SAVED"
        }
    }

    /// 表单里「作品名称」这一栏的标签，按类型换用更自然的叫法。
    var titleFieldLabel: String {
        switch self {
        case .movie: return "片名"
        case .book: return "书名"
        case .comic: return "漫画名"
        case .music: return "专辑或单曲"
        case .podcast: return "节目名"
        case .game: return "游戏名"
        case .other: return "作品名称"
        }
    }

    /// 「作者 / 导演 / 艺术家」这一栏的标签，不同类型使用不同称呼。
    var creatorFieldLabel: String {
        switch self {
        case .movie: return "导演"
        case .book, .comic: return "作者"
        case .music: return "艺术家"
        case .podcast: return "主播"
        case .game: return "开发者"
        case .other: return "创作者"
        }
    }

    /// 作品名称输入框的提示文字。
    var titleFieldPlaceholder: String {
        switch self {
        case .movie: return "例如：花样年华"
        case .book: return "例如：海边的卡夫卡"
        case .comic: return "例如：灌篮高手"
        case .music: return "例如：冀西南林路行"
        case .podcast: return "例如：忽左忽右"
        case .game: return "例如：风之旅人"
        case .other: return "例如：但是还有书籍"
        }
    }
}
