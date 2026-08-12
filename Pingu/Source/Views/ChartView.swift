//
//  ChartView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa

class ChartView {

    // MARK: - Public Properties

    public var desiredWidth: CGFloat {
        let titleWidth = (title as NSString).size(withAttributes: [.font: titleFont]).width
        return chartImageSize.width + titleSpacing + ceil(titleWidth)
    }

    // MARK: - Private Properties

    private weak var statusBarButton: NSStatusBarButton?
    private var title = "n/a"
    private var isReset = false
    private var results: [PingResult] = Array(repeating: .responseInMilliseconds(0), count: 6)

    private let titleSpacing: CGFloat = 4
    private let titleFont = NSFont.menuBarFont(ofSize: 0)
    private let chartImageSize = NSSize(width: 26, height: 16)
    private let barWidth: CGFloat = 2
    private let barSpacing: CGFloat = 2
    private let barBottom: CGFloat = 4
    private let maxBarHeight: CGFloat = 12
    // Template images cannot retain hue, so preserve the three latency
    // categories as distinct monochrome intensities instead.
    private let normalBarOpacity: CGFloat = 1.0
    private let highPingBarOpacity: CGFloat = 0.55
    private let veryHighPingBarOpacity: CGFloat = 0.4

    private var avgResponseTime: Float {
        let values = results.compactMap { result -> Int? in
            if case .responseInMilliseconds(let value) = result {
                return value
            }
            return nil
        }

        return values.isEmpty ? 0 : Float(values.reduce(0, +) / values.count)
    }

    // MARK: - Public Methods

    public func attach(to statusBarButton: NSStatusBarButton) {
        self.statusBarButton = statusBarButton

        statusBarButton.isBordered = false
        statusBarButton.imagePosition = .imageLeft
        statusBarButton.imageScaling = .scaleNone
        statusBarButton.imageHugsTitle = true
        statusBarButton.font = titleFont

        updateStatusBarButton()
    }

    public func addResult(_ pingResult: PingResult) {
        results.append(pingResult)

        if results.count > 6 {
            results = Array(results.dropFirst())
        }

        isReset = false

        switch pingResult {
        case .responseInMilliseconds(let value):
            title = "\(value)ms"
        case .timeout:
            title = "t/o"
        default:
            title = "n/a"
        }

        updateStatusBarButton()
    }

    public func setPausedState(_ paused: Bool) {
        if paused {
            reset()
        }
    }

    public func reset() {
        title = "n/a"
        isReset = true
        results = Array(repeating: .responseInMilliseconds(0), count: 6)
        updateStatusBarButton()
    }

    // MARK: - Private Methods

    private func updateStatusBarButton() {
        guard let statusBarButton else { return }

        statusBarButton.title = title
        statusBarButton.image = makeTemplateChartImage()
    }

    private func makeTemplateChartImage() -> NSImage {
        let image = NSImage(size: chartImageSize)
        image.lockFocus()

        if !isReset {
            for (index, result) in results.enumerated() {
                let height = barHeight(for: result)
                guard height > 0 else { continue }

                NSColor.black.withAlphaComponent(barOpacity(for: result)).setFill()

                let x = CGFloat(index) * (barWidth + barSpacing)
                NSRect(x: x,
                       y: barBottom,
                       width: barWidth,
                       height: height).fill()
            }
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func barOpacity(for result: PingResult) -> CGFloat {
        guard case .responseInMilliseconds(let value) = result else { return 0 }

        switch value {
        case 0..<80:
            return normalBarOpacity
        case 80..<150:
            return highPingBarOpacity
        default:
            return veryHighPingBarOpacity
        }
    }

    private func barHeight(for result: PingResult) -> CGFloat {
        switch result {
        case .responseInMilliseconds(let value):
            let scaledValue = Rescale(from: (0, Float(avgResponseTime * 2)),
                                      to: (1, Float(maxBarHeight))).rescale(Float(value))
            return min(CGFloat(scaledValue), maxBarHeight)
        case .timeout:
            return 0
        default:
            return 0
        }
    }

}
