//
//  DemoRow.swift
//  TableViewDemo
//
//  Created by Chao on 2026/9/20.
//

import Foundation

/// UITableView 动态高度演示使用的数据模型
struct DemoRow {
    /// 当前行的标题
    let title: String

    /// 当前行支持多行显示的正文
    let detail: String

    /// 创建具有不同正文行数的测试数据
    /// - Parameter count: 需要创建的数据条数
    /// - Returns: 用于动态高度演示的数据数组
    static func makeRows(count: Int) -> [DemoRow] {
        let sentences = [
            "UITableView 会根据 Auto Layout 约束计算这一行的真实高度。",
            "屏幕外的 Cell 是否立即测量，是两个页面最值得观察的差别。",
            "滚动页面时，可以继续观察 contentSize.height 是否发生修正。"
        ]

        return (0..<count).map { index in
            let lineCount = [1, 2, 3, 5, 7][index % 5]
            let detail = (0..<lineCount)
                .map { sentences[(index + $0) % sentences.count] }
                .joined(separator: "\n")
            return DemoRow(title: "Row \(index)", detail: detail)
        }
    }
}
