//
//  MediaTags.swift
//  Mosaic
//
//  标签的轻量规范化：逗号（中英文）、顿号、井号都当分隔符，
//  去空白、去重但保留标签内部的空格（例如 "non fiction"）。
//

import Foundation

enum MediaTags {
    private static let separators: Set<Character> = [",", "，", "、", "#", "＃"]

    /// "文学, 小说，小说 #重读" → ["文学", "小说", "重读"]
    static func parse(_ raw: String) -> [String] {
        var seen = Set<String>()
        var tags: [String] = []

        for piece in raw.split(whereSeparator: { separators.contains($0) }) {
            let tag = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tag.isEmpty else { continue }
            guard seen.insert(tag.lowercased()).inserted else { continue }
            tags.append(tag)
        }
        return tags
    }

    /// 统一存成半角逗号分隔的文本，避免同一语义出现多种写法。
    static func serialize(_ tags: [String]) -> String {
        parse(tags.joined(separator: ",")).joined(separator: ",")
    }
}
