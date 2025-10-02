/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore
import ScanditBarcodeCapture
import ScanditFrameworksCore


public class FrameworksSparkScanView: FrameworksBaseView {
    private let modeListener: FrameworksSparkScanListener
    private let viewListener: FrameworksSparkScanViewUIListener
    private let feedbackDelegate: FrameworksSparkScanFeedbackDelegate
    private let modeDeserializer: SparkScanDeserializer
    private let viewDeserializer: SparkScanViewDeserializer

    private var _viewId: Int = 0
    public var viewId: Int {
        return _viewId
    }
    
    public var parentId: Int? { nil }

    private var view: SparkScanView!
    private var mode: SparkScan!
    private var shouldShowOnTopAlways: Bool = false

    private init(
        modeListener: FrameworksSparkScanListener,
        viewListener: FrameworksSparkScanViewUIListener,
        feedbackDelegate: FrameworksSparkScanFeedbackDelegate,
        modeDeserializer: SparkScanDeserializer = SparkScanDeserializer(),
        viewDeserializer: SparkScanViewDeserializer = SparkScanViewDeserializer()
    ) {
        self.modeListener = modeListener
        self.viewListener = viewListener
        self.feedbackDelegate = feedbackDelegate
        self.modeDeserializer = modeDeserializer
        self.viewDeserializer = viewDeserializer
    }

    private func deserializeView(context: DataCaptureContext, container: UIView, viewCreationParams: SparkScanViewCreationData) throws {
        _viewId = viewCreationParams.viewId

        mode = try modeDeserializer.mode(fromJSONString: viewCreationParams.modeJson)
        shouldShowOnTopAlways = viewCreationParams.shouldShowOnTopAlways

        view = try viewDeserializer.view(
            fromJSONString: viewCreationParams.viewJson,
            with: context,
            mode: mode,
            parentView: container
        )

        view.tag = viewId
        view.prepareScanning()

        postModeCreate(viewCreationParams)
        postViewCreation(viewCreationParams)
    }

    private func findViewWithTag(_ container: UIView, tag: Int) -> UIView? {
        if container.tag == tag {
            return container
        }

        for subview in container.subviews {
            if let foundView = findViewWithTag(subview, tag: tag) {
                return foundView
            }
        }

        return nil
    }
    
    private func postModeCreate(_ creationData: SparkScanViewCreationData) {
        if creationData.hasModeListener {
            mode.removeListener(modeListener)
            mode.addListener(modeListener)
            modeListener.enable()
        } else {
            mode.removeListener(modeListener)
            modeListener.disable()
        }
    }

    private func postViewCreation(_ creationData: SparkScanViewCreationData) {
        if creationData.hasUIListener {
            view.uiDelegate = viewListener
            viewListener.enable()
        } else {
            view.uiDelegate = nil
            viewListener.disable()
        }

        if creationData.hasFeedbackDelegate {
            view.feedbackDelegate = feedbackDelegate
        } else {
            view.feedbackDelegate = nil
        }
    }

    public func updateView(viewJson: String) {
        let updateParams = SparkScanViewCreationData.fromJson(viewJson)
        dispatchMain {
            do {
                try self.viewDeserializer.update(self.view, fromJSONString: updateParams.viewJson)
                self.postViewCreation(updateParams)
            } catch {
                Log.error(error)
            }
        }
    }
    
    public func addFeedbackDelegate() {
        self.view.feedbackDelegate = feedbackDelegate
    }
    
    public func removeFeedbackDelegate() {
        self.view.feedbackDelegate = nil
    }

    public func submitFeedback(feedbackJson: String?) {
        feedbackDelegate.submitFeedback(feedbackJson: feedbackJson)
    }

    public func enableSparkScanListener() {
        modeListener.enable()
    }

    public func disableSparkScanListener() {
        modeListener.disable()
    }

    public func dispose() {
        dispatchMain {
            self.modeListener.disable()
            self.mode.removeListener(self.modeListener)
            self.view.uiDelegate = nil
            self.view.stopScanning()
            self.view.feedbackDelegate = nil
            self.view.removeFromSuperview()
        }
    }
    
    public func prepareScanning() {
        dispatchMain {
            self.view.prepareScanning()
        }
    }

    public func startScanning() {
        dispatchMain {
            self.view.startScanning()
        }
    }

    public func pauseScanning() {
        dispatchMain {
            self.view.pauseScanning()
        }
    }
    
    public func stopScanning() {
        dispatchMain {
            self.view.stopScanning()
        }
    }

    public func updateMode(modeJson: String) throws {
        try modeDeserializer.updateMode(mode, fromJSONString: modeJson)
    }

    public func finishDidUpdateCallback(enabled: Bool) {
        modeListener.finishDidUpdate(enabled: enabled)
    }

    public func finishDidScanCallback(enabled: Bool) {
        modeListener.finishDidScan(enabled: enabled)
    }

    public func resetLastSession() {
        modeListener.resetLastSession()
    }

    public func addSparkScanViewUiListener() {
        view.uiDelegate = viewListener
        viewListener.enable()
    }

    public func removeSparkScanViewUiListener() {
        view.uiDelegate = nil
        viewListener.disable()
    }

    public func showToast(text: String) {
        dispatchMain {
            self.view.showToast(text)
        }
    }

    public func setModeEnabled(_ enabled: Bool) {
        mode.isEnabled = enabled
    }

    public func isModeEnabled() -> Bool {
        return mode.isEnabled
    }
    
    public func bringViewToTop() -> Void {
        if !shouldShowOnTopAlways {
            return
        }
        guard let parent = view.superview else {
            return
        }
        dispatchMain {
            parent.bringSubviewToFront(self.view)
        }
    }
    
    public func setupViewConstraints(referenceView: UIView) {
        guard let parent = self.view.superview else { return }
        let sparkScanViewConstraints = parent.constraints.filter {
            $0.firstItem === self.view
        }
        parent.removeConstraints(sparkScanViewConstraints)
        parent.addConstraints([
            self.view.topAnchor.constraint(equalTo: referenceView.topAnchor),
            self.view.leadingAnchor.constraint(equalTo: referenceView.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: referenceView.trailingAnchor),
            self.view.bottomAnchor.constraint(equalTo: referenceView.bottomAnchor),
        ])
    }
    
    public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.view.hitTest(point, with: event)
    }
    
    public func show() {
        dispatchMain {
            self.view.isHidden = false
        }
    }
    
    public func hide() {
        dispatchMain {
            self.view.pauseScanning()
            self.view.isHidden = true
        }
    }

    public static func create(
        emitter: Emitter,
        context: DataCaptureContext,
        container: UIView,
        viewCreationParams: SparkScanViewCreationData
    ) throws -> FrameworksSparkScanView {
        let modeListener = FrameworksSparkScanListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let viewListener = FrameworksSparkScanViewUIListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let feedbackDelegate = FrameworksSparkScanFeedbackDelegate(emitter: emitter, viewId: viewCreationParams.viewId)

        let instance = FrameworksSparkScanView(
            modeListener: modeListener,
            viewListener: viewListener,
            feedbackDelegate: feedbackDelegate
        )

        try instance.deserializeView(context: context, container: container, viewCreationParams: viewCreationParams)
        return instance
    }
}
