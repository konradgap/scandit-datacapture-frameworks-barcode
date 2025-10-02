/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import QuartzCore
import ScanditFrameworksCore
import ScanditCaptureCore
import ScanditBarcodeCapture

public enum BarcodeArCustomHighlightEvents: String, CaseIterable {
    case createCustomHighlight = "BarcodeArCustomHighlight.create"
    case updateCustomHighlight = "BarcodeArCustomHighlight.update"
    case hideCustomHighlight = "BarcodeArCustomHighlight.hide"
    case showeCustomHighlight = "BarcodeArCustomHighlight.show"
    case disposeCustomHighlight = "BarcodeArCustomHighlight.dispose"
}

class BarcodeArCustomHighlight: UIView, BarcodeArHighlight {
    var barcode: Barcode
    var emitter: Emitter
    private var hasEmittedOnce = false

    init(barcode: Barcode, emitter: Emitter) {
        self.barcode = barcode
        self.emitter = emitter

        super.init(frame: .zero)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            create()
        } else {
            dispose()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Sometimes highlights are hidden before being removed.
    override var isHidden: Bool {
        didSet {
            if isHidden {
                hide()
            } else {
                show()
            }
        }
    }

    func hide() {
        self.emitter.emit(
            name: BarcodeArCustomHighlightEvents.hideCustomHighlight.rawValue,
            payload: ["barcodeId": self.barcode.uniqueId]
        )
    }

    func show() {
        self.emitter.emit(
            name: BarcodeArCustomHighlightEvents.showeCustomHighlight.rawValue,
            payload: ["barcodeId": self.barcode.uniqueId]
        )

    }

    func create() {
        self.emitter.emit(
            name: BarcodeArCustomHighlightEvents.createCustomHighlight.rawValue,
            payload: [
                "barcode": self.barcode.jsonString,
                "barcodeId": self.barcode.uniqueId,
            ]
        )
    }

    func dispose() {
        self.emitter.emit(
            name: BarcodeArCustomHighlightEvents.disposeCustomHighlight.rawValue,
            payload: [
                "barcodeId": self.barcode.uniqueId
            ]
        )

    }

    func update(with location: Quadrilateral) {
        let centerX = (location.bottomLeft.x + location.bottomRight.x + location.topLeft.x + location.topRight.x) / 4
        let centerY = (location.bottomLeft.y + location.bottomRight.y + location.topLeft.y + location.topRight.y) / 4
        // CGPoint.jsonString is internal and this is a direct copy of that implementation
        let centerJson = """
            {"x": \(centerX), "y": \(centerY)}
            """

        let payload: [String: Any] = [
            "centerPosition": centerJson,
            "barcodeId": self.barcode.uniqueId,
        ]

        // We emit once immediately to avoid initial lag
        if !hasEmittedOnce {
            emitter.emit(
                name: BarcodeArCustomHighlightEvents.updateCustomHighlight.rawValue,
                payload: payload
            )
            hasEmittedOnce = true
            return
        }

        BarcodeArCustomHighlight.batchedEmit(emitter: emitter, payload: payload)
    }

    // MARK: - Static batching logic
    private static let emitInterval: TimeInterval = 1.0 / 30.0  // 30 emits per second
    private static var lastEmitTime: TimeInterval = 0
    private static var pendingUpdates: [[String: Any]] = []
    private static var emitTimer: Timer?

    private static func batchedEmit(emitter: Emitter, payload: [String: Any]) {
        pendingUpdates.append(payload)

        // We have a pending emit, no need to schedule another one
        if emitTimer != nil {
            return
        }

        let currentTime = CACurrentMediaTime()
        let timeUntilNextEmit = emitInterval - (currentTime - lastEmitTime)
        let delay = max(0, timeUntilNextEmit)

        emitTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            let batchedPayload: [String: Any] = [
                "updates": pendingUpdates
            ]
            pendingUpdates.removeAll()
            lastEmitTime = CACurrentMediaTime()
            emitter.emit(
                name: BarcodeArCustomHighlightEvents.updateCustomHighlight.rawValue,
                payload: batchedPayload
            )
            emitTimer = nil
        }
    }

}
