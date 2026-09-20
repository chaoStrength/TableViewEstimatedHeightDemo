//
//  TableHeightViewController.swift
//  TableViewDemo
//
//  Created by Chao on 2026/9/20.
//

import UIKit

/// UITableView 动态高度对比演示的基础视图控制器
class TableHeightViewController: UIViewController {

    /// 表格高度计算模式
    enum Mode {
        /// 使用预估行高并在滚动过程中修正真实高度
        case estimated

        /// 首次加载时同步计算全部真实行高
        case nonEstimated

        /// 当前模式对应的页面标题
        var title: String {
            switch self {
            case .estimated:
                return "使用 Estimated Height"
            case .nonEstimated:
                return "不使用 Estimated Height"
            }
        }

        /// 当前模式对应的日志前缀
        var logPrefix: String {
            switch self {
            case .estimated:
                return "Estimated ON"
            case .nonEstimated:
                return "Estimated OFF"
            }
        }

        /// 当前模式对应的预估行高
        var estimatedRowHeight: CGFloat {
            switch self {
            case .estimated:
                return 80
            case .nonEstimated:
                return 0
            }
        }
    }

    /// 当前页面使用的高度计算模式
    private let mode: Mode

    /// 用于展示动态行高的测试数据
    private let rows = DemoRow.makeRows(count: 40)

    /// 展示测试数据的表格视图
    private let tableView = UITableView(frame: .zero, style: .plain)

    /// 在不使用预估行高时负责离屏测量的 Cell
    private let sizingCell = DynamicHeightCell(style: .default, reuseIdentifier: nil)

    /// contentSize 变化观察对象
    private var contentSizeObservation: NSKeyValueObservation?

    /// 按行号缓存的真实行高
    private var measuredHeights: [Int: CGFloat] = [:]

    /// 当前高度缓存对应的表格宽度
    private var measurementWidth: CGFloat = 0

    /// 已完成并记录的布局次数
    private var layoutPassCount = 0

    /// 标记测试数据是否已经加载
    private var hasLoadedData = false

    /// 使用指定的高度计算模式创建演示页面
    /// - Parameter mode: 表格高度计算模式
    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.title
        view.backgroundColor = .systemBackground

        configureTableView()
        observeContentSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasLoadedData else {
            logState("viewDidAppear（页面再次显示）")
            return
        }

        // 此时页面已经加入 window 可以安全地触发布局并读取 contentSize
        hasLoadedData = true
        reloadAndLog()
        logState("viewDidAppear（页面已显示）")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard hasLoadedData else { return }

        layoutPassCount += 1
        if layoutPassCount <= 3 {
            logState("viewDidLayoutSubviews 第 \(layoutPassCount) 次")
        }
    }

    /// 配置表格视图及其布局约束
    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = mode.estimatedRowHeight
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(DynamicHeightCell.self, forCellReuseIdentifier: DynamicHeightCell.reuseIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// 观察并输出表格内容尺寸的高度变化
    private func observeContentSize() {
        contentSizeObservation = tableView.observe(\.contentSize, options: [.old, .new]) { [weak self] _, change in
            guard let self,
                  let oldHeight = change.oldValue?.height,
                  let newHeight = change.newValue?.height,
                  oldHeight != newHeight else { return }

            self.log(
                "contentSize.height 变化: "
                + "\(self.formatted(oldHeight)) -> \(self.formatted(newHeight))"
            )
        }
    }

    /// 重新加载数据并输出关键布局阶段的状态
    private func reloadAndLog() {
        log("--------------------------------------------------")
        log("数据条数: \(rows.count)")
        log("rowHeight: automaticDimension")
        log("estimatedRowHeight: \(formatted(tableView.estimatedRowHeight))")
        if mode == .nonEstimated {
            log("高度策略: heightForRowAt 同步测量全部 Cell 的真实高度")
        }

        tableView.reloadData()
        logState("reloadData 刚返回")

        view.layoutIfNeeded()
        logState("layoutIfNeeded 刚返回")

        DispatchQueue.main.async { [weak self] in
            self?.logState("下一个 RunLoop")
        }
    }

    /// 输出指定阶段的 contentSize 和可见行信息
    /// - Parameter stage: 当前布局阶段的描述
    private func logState(_ stage: String) {
        let visibleRows = tableView.indexPathsForVisibleRows?
            .map(\.row)
            .sorted()
            .map(String.init)
            .joined(separator: ", ") ?? "无"

        log(
            "\(stage) | contentSize.height = \(formatted(tableView.contentSize.height))"
            + " | 可见 row = [\(visibleRows)]"
        )
    }

    /// 输出带有当前模式前缀的日志
    /// - Parameter message: 日志内容
    private func log(_ message: String) {
        print("[\(mode.logPrefix)] \(message)")
    }

    /// 将高度格式化为保留一位小数的字符串
    /// - Parameter value: 需要格式化的高度
    /// - Returns: 格式化后的高度字符串
    private func formatted(_ value: CGFloat) -> String {
        String(format: "%.1f", value)
    }

    /// 同步测量并缓存指定行的真实高度
    /// - Parameter indexPath: 需要测量的行位置
    /// - Returns: 测量并取整后的行高
    private func measuredHeight(at indexPath: IndexPath) -> CGFloat {
        let width = tableView.bounds.width
        guard width > 0 else { return 44 }

        if measurementWidth != width {
            measurementWidth = width
            measuredHeights.removeAll()
        }

        if let cachedHeight = measuredHeights[indexPath.row] {
            return cachedHeight
        }

        sizingCell.configure(with: rows[indexPath.row])

        let targetSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let height = sizingCell.contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let measuredHeight = ceil(height)
        measuredHeights[indexPath.row] = measuredHeight
        log("heightForRowAt row \(indexPath.row) | 同步计算高度 = \(formatted(measuredHeight))")
        return measuredHeight
    }
}

// MARK: - UITableViewDataSource

extension TableHeightViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        hasLoadedData ? rows.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DynamicHeightCell.reuseIdentifier,
            for: indexPath
        ) as? DynamicHeightCell else {
            return UITableViewCell()
        }

        cell.configure(with: rows[indexPath.row])
        log("cellForRowAt row \(indexPath.row)")
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TableHeightViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard mode == .nonEstimated else {
            return UITableView.automaticDimension
        }

        return measuredHeight(at: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        log(
            "willDisplay row \(indexPath.row)"
            + " | 实际高度 = \(formatted(cell.bounds.height))"
            + " | contentSize.height = \(formatted(tableView.contentSize.height))"
        )
    }
}
