//
//  ViewController.swift
//  TableViewDemo
//
//  Created by Chao on 2026/9/20.
//

import UIKit

/// UITableView 动态高度演示的入口页面
class ViewController: UIViewController {

    /// 进入使用预估行高演示页面的按钮
    private lazy var estimatedHeightButton = makeButton(
        title: "使用 Estimated Height",
        action: #selector(showEstimatedHeightDemo)
    )

    /// 进入不使用预估行高演示页面的按钮
    private lazy var nonEstimatedHeightButton = makeButton(
        title: "不使用 Estimated Height",
        action: #selector(showNonEstimatedHeightDemo)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UITableView 高度演示"
        view.backgroundColor = .white

        let stackView = UIStackView(arrangedSubviews: [
            estimatedHeightButton,
            nonEstimatedHeightButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            estimatedHeightButton.heightAnchor.constraint(equalToConstant: 52),
            nonEstimatedHeightButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    /// 创建统一样式的演示入口按钮
    /// - Parameters:
    ///   - title: 按钮标题
    ///   - action: 点击按钮时执行的方法
    /// - Returns: 配置完成的按钮
    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    /// 进入使用预估行高的演示页面
    @objc private func showEstimatedHeightDemo() {
        navigationController?.pushViewController(EstimatedHeightViewController(), animated: true)
    }

    /// 进入不使用预估行高的演示页面
    @objc private func showNonEstimatedHeightDemo() {
        navigationController?.pushViewController(NonEstimatedHeightViewController(), animated: true)
    }
}
