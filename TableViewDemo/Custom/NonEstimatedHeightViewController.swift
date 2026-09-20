//
//  NonEstimatedHeightViewController.swift
//  TableViewDemo
//
//  Created by Chao on 2026/9/20.
//

import UIKit

/// 展示不使用预估行高时 UITableView 布局过程的视图控制器
final class NonEstimatedHeightViewController: TableHeightViewController {

    /// 创建不使用预估行高的演示页面
    init() {
        super.init(mode: .nonEstimated)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
