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

public class FrameworksBarcodeArView: FrameworksBaseView {

    private let barcodeArListener: FrameworksBarcodeArListener
    private let barcodeArViewUiDelegate: FrameworksBarcodeArViewUiListener
    private let highlightProvider: FrameworksBarcodeArHighlightProvider
    private let annotationProvider: FrameworksBarcodeArAnnotationProvider
    private let infoAnnotationDelegate: FrameworksInfoAnnotationDelegate
    private let popoverAnnotationDelegate: FrameworksPopoverAnnotationDelegate
    private let deserializer: BarcodeArDeserializer
    private let viewDeserializer: BarcodeArViewDeserializer

    public var view: BarcodeArView!
    public var parentId: Int? { nil }

    private var context: DataCaptureContext
    private var augmentationsCache: BarcodeArAugmentationsCache

    private var mode: BarcodeAr!

    private var _viewId: Int = 0
    public var viewId: Int { _viewId }

    private init(
        barcodeArListener: FrameworksBarcodeArListener,
        barcodeArViewUiDelegate: FrameworksBarcodeArViewUiListener,
        highlightProvider: FrameworksBarcodeArHighlightProvider,
        annotationProvider: FrameworksBarcodeArAnnotationProvider,
        infoAnnotationDelegate: FrameworksInfoAnnotationDelegate,
        popoverAnnotationDelegate: FrameworksPopoverAnnotationDelegate,
        context: DataCaptureContext,
        augmentationsCache: BarcodeArAugmentationsCache,
        deserializer: BarcodeArDeserializer = BarcodeArDeserializer(),
        viewDeserializer: BarcodeArViewDeserializer = BarcodeArViewDeserializer()
    ) {
        self.barcodeArListener = barcodeArListener
        self.barcodeArViewUiDelegate = barcodeArViewUiDelegate
        self.highlightProvider = highlightProvider
        self.annotationProvider = annotationProvider
        self.infoAnnotationDelegate = infoAnnotationDelegate
        self.popoverAnnotationDelegate = popoverAnnotationDelegate
        self.context = context
        self.augmentationsCache = augmentationsCache
        self.deserializer = deserializer
        self.viewDeserializer = viewDeserializer
    }

    private func deserializeView(
        parent: UIView,
        context: DataCaptureContext,
        viewCreationParams: BarcodeArViewCreationData
    ) throws {
        _viewId = viewCreationParams.viewId

        mode = try deserializer.mode(fromJSONString: viewCreationParams.modeJson, context: context)

        view = try viewDeserializer.view(
            fromJSONString: viewCreationParams.viewJson,
            parentView: parent,
            mode: mode
        )

        view.tag = viewId
        parent.tag = viewId

        postModeCreation(viewCreationParams)
        postViewCreation(viewCreationParams)
    }

    private func postModeCreation(_ creationData: BarcodeArViewCreationData) {
        if creationData.hasModeListener {
            mode.addListener(barcodeArListener)
        } else {
            mode.removeListener(barcodeArListener)
        }
    }

    private func postViewCreation(_ creationData: BarcodeArViewCreationData) {
        if creationData.hasUIListener {
            addBarcodeArViewUiListener()
        } else {
            removeBarcodeArViewUiListener()
        }

        if creationData.hasHighlightProvider {
            addBarcodeArHighlightProvider()
        } else {
            removeBarcodeArHighlightProvider()
        }

        if creationData.hasAnnotationProvider {
            addBarcodeArAnnotationProvider()
        } else {
            removeBarcodeArAnnotationProvider()
        }

        if creationData.isStarted {
            startMode()
        }
    }

    public func updateView(viewJson: String) {
        do {
            let updateParams = try BarcodeArViewCreationData.fromViewJsonOnly(viewJson)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                _ = try? self.viewDeserializer.update(self.view, fromJSONString: updateParams.viewJson)
                self.postViewCreation(updateParams)
            }

        } catch {
            Log.error("Failed to update BarcodeAr view.", error: error)
        }
    }

    public func updateMode(modeJson: String) {
        do {
            let updateParams = try BarcodeArViewCreationData.fromModeJsonOnly(modeJson)
            _ = try? deserializer.updateMode(mode, fromJSONString: updateParams.modeJson)
            postModeCreation(updateParams)
        } catch {
            Log.error("Failed to update BarcodeAr mode.", error: error)
        }
    }

    public func addBarcodeArViewUiListener() {
        view.uiDelegate = barcodeArViewUiDelegate
    }

    public func removeBarcodeArViewUiListener() {
        view.uiDelegate = nil
    }

    public func addBarcodeArHighlightProvider() {
        view.highlightProvider = highlightProvider
    }

    public func removeBarcodeArHighlightProvider() {
        view.highlightProvider = nil
    }

    public func addBarcodeArAnnotationProvider() {
        view.annotationProvider = annotationProvider
    }

    public func removeBarcodeArAnnotationProvider() {
        view.annotationProvider = nil
    }

    public func addBarcodeArListener() {
        mode.addListener(barcodeArListener)
    }

    public func removeBarcodeArListener() {
        mode.removeListener(barcodeArListener)
    }

    public func finishDidUpdateSession(enabled: Bool) {
        barcodeArListener.finishDidUpdateSession(enabled: enabled)
    }

    public func updateFeedback(feedbackJson: String) throws {
        mode.feedback = try BarcodeArFeedback(fromJSONString: feedbackJson)
    }

    public func resetSession() {
        barcodeArListener.resetSession()
    }

    public func applySettings(settingsJson: String) throws {
        let settings = try deserializer.settings(fromJSONString: settingsJson)
        mode.apply(settings)
    }

    public func startMode() {
        view.start()
    }

    public func stopMode() {
        view.stop()
    }

    public func hide() {
        barcodeArListener.resetSession()
        dispatchMain {
            self.view.pause()
            self.view.isHidden = true
        }
    }

    public func show() {
        dispatchMain {
            self.view.isHidden = false
            self.view.superview?.bringSubviewToFront(self.view)
            self.view.start()
        }
    }
    
    public func dispose() {
        print("ilber -> Dispose view \(viewId)")
        barcodeArListener.finishDidUpdateSession(enabled: true)
        mode.removeListener(barcodeArListener)
        
        dispatchMain { [weak self] in
            guard let self = self else { return }
            self.view.uiDelegate = nil
            self.view.highlightProvider = nil
            self.view.annotationProvider = nil
            self.view.removeFromSuperview()
        }
    }

    public static func create(
        emitter: Emitter,
        parent: UIView,
        context: DataCaptureContext,
        viewCreationParams: BarcodeArViewCreationData,
        augmentationsCache: BarcodeArAugmentationsCache
    ) throws -> FrameworksBarcodeArView {
        let barcodeArListener = FrameworksBarcodeArListener(emitter: emitter, viewId: viewCreationParams.viewId, cache: augmentationsCache)
        let barcodeArViewUiDelegate = FrameworksBarcodeArViewUiListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let highlightProvider = FrameworksBarcodeArHighlightProvider(
            emitter: emitter,
            viewId: viewCreationParams.viewId,
            parser: BarcodeArHighlightParser(emitter: emitter),
            cache: augmentationsCache
        )
        let infoAnnotationDelegate = FrameworksInfoAnnotationDelegate(emitter: emitter, viewId: viewCreationParams.viewId)
        let popoverAnnotationDelegate = FrameworksPopoverAnnotationDelegate(emitter: emitter, viewId: viewCreationParams.viewId)

        let annotationParser = BarcodeArAnnotationParser()
        annotationParser.setDelegates(
            infoAnnotationDelegate: infoAnnotationDelegate,
            popoverAnnotationDelegate: popoverAnnotationDelegate,
            cache: augmentationsCache
        )

        let annotationProvider = FrameworksBarcodeArAnnotationProvider(
            emitter: emitter,
            viewId: viewCreationParams.viewId,
            parser: annotationParser,
            cache: augmentationsCache
        )

        let instance = FrameworksBarcodeArView(
            barcodeArListener: barcodeArListener,
            barcodeArViewUiDelegate: barcodeArViewUiDelegate,
            highlightProvider: highlightProvider,
            annotationProvider: annotationProvider,
            infoAnnotationDelegate: infoAnnotationDelegate,
            popoverAnnotationDelegate: popoverAnnotationDelegate,
            context: context,
            augmentationsCache: augmentationsCache
        )

        try instance.deserializeView(parent: parent, context: context, viewCreationParams: viewCreationParams)
        return instance
    }

    public func finishHighlightForBarcode(highlightJson: String) {
        highlightProvider.finishHighlightForBarcode(highlightJson: highlightJson)
    }

    public func finishAnnotationForBarcode(annotationJson: String) {
        annotationProvider.finishAnnotationForBarcode(annotationJson: annotationJson)
    }

    public func updateBarcodeArPopoverButtonAtIndex(updateJson: String) {
        annotationProvider.updateBarcodeArPopoverButtonAtIndex(updateJson: updateJson)
    }

    public func updateHighlight(highlightJson: String) {
        highlightProvider.updateHighlight(highlightJson: highlightJson)
    }

    public func updateAnnotation(annotationJson: String) {
        annotationProvider.updateAnnotation(annotationJson: annotationJson)
    }
}
