/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore
import ScanditBarcodeCapture
import ScanditFrameworksCore
import UIKit

public class FrameworksBarcodeFindView: FrameworksBaseView {
    private let modeListener: FrameworksBarcodeFindListener
    private let viewListener: FrameworksBarcodeFindViewUIListener
    private let findTransformer: FrameworksBarcodeFindTransformer
    private let deserializer: BarcodeFindDeserializer
    private let viewDeserializer: BarcodeFindViewDeserializer

    private var _viewId: Int = 0
    public var viewId: Int {
        return _viewId
    }

    public var parentId: Int? { nil } // BarcodeFindView has no parent

    public private(set) var view: BarcodeFindView!

    private var mode: BarcodeFind!

    private init(
        modeListener: FrameworksBarcodeFindListener,
        viewListener: FrameworksBarcodeFindViewUIListener,
        findTransformer: FrameworksBarcodeFindTransformer,
        deserializer: BarcodeFindDeserializer = BarcodeFindDeserializer(),
        viewDeserializer: BarcodeFindViewDeserializer = BarcodeFindViewDeserializer()
    ) {
        self.modeListener = modeListener
        self.viewListener = viewListener
        self.findTransformer = findTransformer
        self.deserializer = deserializer
        self.viewDeserializer = viewDeserializer
    }

    private func deserializeView(
        context: DataCaptureContext,
        container: UIView,
        creationData: BarcodeFindViewCreationData
    ) throws {
        try dispatchMainSync {
            _viewId = creationData.viewId
            mode = try deserializer.mode(fromJSONString: creationData.modeJson)
            mode.isEnabled = creationData.isModeEnabled
            updateModeProps(creationData: creationData)
            
            view = try viewDeserializer.view(
                fromJSONString: creationData.viewJson,
                with: context,
                mode: mode,
                parentView: container
            )
            view.prepareSearching()
            updateViewProps(creationData: creationData)
            view.tag = viewId
            container.tag = viewId
        }
    }

    public func updateBarcodeFindView(viewJson: String) {
        let updateParams = BarcodeFindViewCreationData.fromViewJsonOnly(viewJson: viewJson)
        dispatchMain { [weak self] in
            guard let self = self else { return }
            do {
                try self.viewDeserializer.update(self.view, fromJSONString: updateParams.viewJson)
            } catch {
                Log.error(error)
            }
        }
        updateViewProps(creationData: updateParams)
    }

    public func updateBarcodeFindMode(modeJson: String) {
        let updateParams = BarcodeFindViewCreationData.fromModeJsonOnly(modeJson: modeJson)
        updateModeProps(creationData: updateParams)
    }

    public func addBarcodeFindListener() {
        mode.addListener(modeListener)
    }

    public func removeBarcodeFindListener() {
        mode.removeListener(modeListener)
    }

    public func addBarcodeFindViewListener() {
        view.uiDelegate = viewListener
    }

    public func removeBarcodeFindViewListener() {
        view.uiDelegate = nil
    }

    public func setItemList(barcodeFindItemsJson: String) {
        let data = BarcodeFindItemsData(jsonString: barcodeFindItemsJson)
        mode.setItemList(data.items)
    }

    public func viewStopSearching() {
        dispatchMain { [weak self] in
            self?.view.stopSearching()
        }
    }

    public func viewPrepareSearching() {
        dispatchMain { [weak self] in
            self?.view.prepareSearching()
        }
    }

    public func viewStartSearching() {
        dispatchMain { [weak self] in
            self?.view.startSearching()
        }
    }

    public func viewPauseSearching() {
        dispatchMain { [weak self] in
            self?.view.pauseSearching()
        }
    }

    public func modeStart() {
        mode.start()
    }

    public func modeStop() {
        mode.stop()
        findTransformer.cancel()
    }

    public func modePause() {
        mode.pause()
    }

    public func setModeEnabled(enabled: Bool) {
        mode.isEnabled = enabled
    }

    public func setBarcodeFindTransformer() {
        findTransformer.enable()
        mode.setBarcodeTransformer(findTransformer)
    }

    public func submitBarcodeFindTransformerResult(transformedData: String?) {
        findTransformer.submitResult(result: transformedData)
    }
    
    public func unsetBarcodeFindTransformer() {
        findTransformer.disable()
        // The native SDK doesn't support removing the transformer
    }

    public func updateFeedback(feedbackJson: String) throws {
        mode.feedback = try BarcodeFindFeedback(fromJSONString: feedbackJson)
    }

    public func isModeEnabled() -> Bool {
        return mode.isEnabled
    }

    private func updateViewProps(creationData: BarcodeFindViewCreationData) {
        if creationData.hasViewListener {
            view.uiDelegate = viewListener
        }
        if creationData.startSearching {
            view.startSearching()
        }
    }

    private func updateModeProps(creationData: BarcodeFindViewCreationData) {
        if creationData.hasModeListeners {
            mode.addListener(modeListener)
        }
        if creationData.hasBarcodeTransformer {
            mode.setBarcodeTransformer(findTransformer)
        }
        if let itemsToFind = creationData.itemsToFind {
            mode.setItemList(itemsToFind.items)
        } else {
            mode.setItemList(Set<BarcodeFindItem>())
        }
    }

    public func dispose() {
        self.mode.stop()
        self.findTransformer.disable()
        self.mode.removeListener(self.modeListener)
        dispatchMain { [weak self] in
            guard let self = self else { return }
            self.view.stopSearching()
            self.view.uiDelegate = nil
            self.view.removeFromSuperview()
        }
    }

    public func hide() {
        self.mode.pause()
        self.findTransformer.disable()
        dispatchMain { [weak self] in
            guard let self = self else { return }
            self.view.isHidden = true
            self.view.stopSearching()
        }
    }

    public func show() {
        dispatchMain { [weak self] in
            guard let self = self else { return }
            self.view.isHidden = false
            self.view.superview?.bringSubviewToFront(self.view)
            self.view.prepareSearching()
            self.view.startSearching()
            self.mode.start()
            self.findTransformer.enable()
        }
    }

    // MARK: - Factory method

    static func create(
        emitter: Emitter,
        context: DataCaptureContext,
        container: UIView,
        viewCreationParams: BarcodeFindViewCreationData
    ) throws -> FrameworksBarcodeFindView {
        let modeListener = FrameworksBarcodeFindListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let viewListener = FrameworksBarcodeFindViewUIListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let transformerListener = FrameworksBarcodeFindTransformer(emitter: emitter, viewId: viewCreationParams.viewId)

        let instance = FrameworksBarcodeFindView(
            modeListener: modeListener,
            viewListener: viewListener,
            findTransformer: transformerListener
        )

        try instance.deserializeView(context: context, container: container, creationData: viewCreationParams)
        return instance
    }
}
