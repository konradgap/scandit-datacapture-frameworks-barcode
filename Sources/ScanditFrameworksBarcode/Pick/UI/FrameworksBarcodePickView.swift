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

public class FrameworksBarcodePickView: FrameworksBaseView {

    private let barcodePickActionListener: FrameworksBarcodePickActionListener
    private let barcodePickAsyncMapperProductProviderCallback: FrameworksBarcodePickAsyncMapperProductProviderCallback
    private let barcodePickListener: FrameworksBarcodePickListener
    private let barcodePickScanningListener: FrameworksBarcodePickScanningListener
    private var barcodePickViewHighlightStyleAsyncProvider: FrameworksBarcodePickViewHighlightStyleAsyncProvider? = nil
    private var barcodePickViewHighlightStyleCustomViewProvider: FrameworksBarcodePickViewHighlightStyleCustomViewProvider? = nil
    private let barcodePickViewListener: FrameworksBarcodePickViewListener
    private let barcodePickViewUiListener: FrameworksBarcodePickViewUiListener
    private let deserializer: BarcodePickDeserializer

    public var _viewId: Int = -1
    public var viewId: Int { _viewId }
    public var view: BarcodePickView!
    public var parentId: Int? { nil }

    private var context: DataCaptureContext

    private var mode: BarcodePick!

    private init(
        barcodePickActionListener: FrameworksBarcodePickActionListener,
        barcodePickAsyncMapperProductProviderCallback: FrameworksBarcodePickAsyncMapperProductProviderCallback,
        barcodePickListener: FrameworksBarcodePickListener,
        barcodePickScanningListener: FrameworksBarcodePickScanningListener,
        barcodePickViewHighlightStyleAsyncProvider: FrameworksBarcodePickViewHighlightStyleAsyncProvider?,
        barcodePickViewHighlightStyleCustomViewProvider: FrameworksBarcodePickViewHighlightStyleCustomViewProvider?,
        barcodePickViewListener: FrameworksBarcodePickViewListener,
        barcodePickViewUiListener: FrameworksBarcodePickViewUiListener,
        deserializer: BarcodePickDeserializer = BarcodePickDeserializer(),
        context: DataCaptureContext
    ) {
        self.barcodePickActionListener = barcodePickActionListener
        self.barcodePickAsyncMapperProductProviderCallback = barcodePickAsyncMapperProductProviderCallback
        self.barcodePickListener = barcodePickListener
        self.barcodePickScanningListener = barcodePickScanningListener
        self.barcodePickViewHighlightStyleAsyncProvider = barcodePickViewHighlightStyleAsyncProvider
        self.barcodePickViewHighlightStyleCustomViewProvider = barcodePickViewHighlightStyleCustomViewProvider
        self.barcodePickViewListener = barcodePickViewListener
        self.barcodePickViewUiListener = barcodePickViewUiListener
        self.deserializer = deserializer
        self.context = context
    }

    private func deserializeView(
        container: UIView,
        context: DataCaptureContext,
        viewCreationParams: BarcodePickViewCreationData
    ) throws {
        _viewId = viewCreationParams.viewId

        let provider = try deserializer.asyncMapperProductProvider(fromJSONString: viewCreationParams.productProviderJson, delegate: barcodePickAsyncMapperProductProviderCallback)

        mode = try deserializer.mode(fromJSONString: viewCreationParams.modeJson, context: context, productProvider: provider)

        // Common deserializer parameters
        let baseParams = (
            jsonString: viewCreationParams.viewJson,
            topLayoutAnchor: nil as NSLayoutYAxisAnchor?
        )

        // Use parsed highlight style information from viewCreationParams - match original logic exactly
        if !viewCreationParams.hasAsyncProvider {
            // If not using async provider, use the basic view
            view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                       context: context,
                                       topLayoutAnchor: baseParams.topLayoutAnchor,
                                       mode: mode)
        } else {
            // Handle different highlight style types when async provider is enabled
            switch viewCreationParams.highlightType {
            case .dotWithIcons, .rectangularWithIcons:
                if let asyncProvider = barcodePickViewHighlightStyleAsyncProvider {
                    view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                               context: context,
                                               topLayoutAnchor: baseParams.topLayoutAnchor,
                                               mode: mode,
                                               viewHighlightStyleDelegate: asyncProvider)
                } else {
                    view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                               context: context,
                                               topLayoutAnchor: baseParams.topLayoutAnchor,
                                               mode: mode)
                }

            case .customView:
                if let customProvider = barcodePickViewHighlightStyleCustomViewProvider {
                    view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                               context: context,
                                               topLayoutAnchor: baseParams.topLayoutAnchor,
                                               mode: mode,
                                               customViewHighlightStyleDelegate: customProvider)
                } else {
                    view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                               context: context,
                                               topLayoutAnchor: baseParams.topLayoutAnchor,
                                               mode: mode)
                }

            default:
                // Fallback to basic view for unknown types with async provider
                view = try deserializer.view(fromJSONString: baseParams.jsonString,
                                           context: context,
                                           topLayoutAnchor: baseParams.topLayoutAnchor,
                                           mode: mode)
            }
        }

        // Set view and parent tags
        view.tag = viewId
        container.tag = viewId

        // Add the view to its parent container
        container.addSubview(view)

        // Perform post-creation setup
        postModeCreation(viewCreationParams)
        postViewCreation(viewCreationParams)
    }

    private func postModeCreation(_ creationData: BarcodePickViewCreationData) {
        if creationData.hasScanningListeners {
            addBarcodePickScanningListener()
        } else {
            removeBarcodePickScanningListener()
        }
        if creationData.hasListeners {
            addBarcodePickListener()
        } else {
            removeBarcodePickListener()
        }
    }

    private func postViewCreation(_ creationData: BarcodePickViewCreationData) {
        if creationData.hasActionListeners {
            addBarcodePickActionListener()
        } else {
            removeBarcodePickActionListener()
        }
        if creationData.hasViewListeners {
            addBarcodePickViewListener()
        } else {
            removeBarcodePickViewListener()
        }
        if creationData.hasViewUiListener {
            addBarcodePickViewUiListener()
        } else {
            removeBarcodePickViewUiListener()
        }
        if creationData.isStarted {
            startMode()
        }
    }

    public func updateView(viewJson: String) {
        do {
            let updateParams = try BarcodePickViewCreationData.fromViewJsonOnly(viewJson)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                _ = try? self.deserializer.update(self.view, fromJSONString: updateParams.viewJson)
                self.postViewCreation(updateParams)
            }

        } catch {
            Log.error("Failed to update BarcodePickView.", error: error)
        }
    }

    public func updateMode(modeJson: String) {
        do {
            let updateParams = try BarcodePickViewCreationData.fromModeJsonOnly(modeJson)
            _ = try? deserializer.updateMode(mode, fromJSONString: updateParams.modeJson)
            postModeCreation(updateParams)
        } catch {
            Log.error("Failed to update BarcodeAr mode.", error: error)
        }
    }

    public func addBarcodePickScanningListener() {
        mode.addScanningListener(barcodePickScanningListener)
    }

    public func removeBarcodePickScanningListener() {
        mode.removeScanningListener(barcodePickScanningListener)
    }

    public func addBarcodePickListener() {
        mode.addListener(barcodePickListener)
    }

    public func removeBarcodePickListener() {
        mode.removeListener(barcodePickListener)
    }

    public func addBarcodePickActionListener() {
        view.addActionListener(barcodePickActionListener)
    }

    public func removeBarcodePickActionListener() {
        view.removeActionListener(barcodePickActionListener)
    }

    public func addBarcodePickViewListener() {
        view.addListener(barcodePickViewListener)
    }

    public func removeBarcodePickViewListener() {
        view.removeListener(barcodePickViewListener)
    }

    public func addBarcodePickViewUiListener() {
        view.uiDelegate = barcodePickViewUiListener
    }

    public func removeBarcodePickViewUiListener() {
        view.uiDelegate = nil
    }

    public func startMode() {
        view.start()
    }

    public func stopMode() {
        view.stop()
    }

    public func hide() {
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

    public static func create(
        emitter: Emitter,
        parent: UIView,
        context: DataCaptureContext,
        viewCreationParams: BarcodePickViewCreationData
    ) throws -> FrameworksBarcodePickView {
        let barcodePickActionListener = FrameworksBarcodePickActionListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let barcodePickAsyncMapperProductProviderCallback = FrameworksBarcodePickAsyncMapperProductProviderCallback(emitter: emitter, viewId: viewCreationParams.viewId)
        let barcodePickListener = FrameworksBarcodePickListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let barcodePickScanningListener = FrameworksBarcodePickScanningListener(emitter: emitter, viewId: viewCreationParams.viewId)

        // Create providers based on highlight type upfront - only create when needed
        let barcodePickViewHighlightStyleAsyncProvider: FrameworksBarcodePickViewHighlightStyleAsyncProvider?
        if viewCreationParams.hasAsyncProvider &&
           (viewCreationParams.highlightType == .dotWithIcons || viewCreationParams.highlightType == .rectangularWithIcons) {
            barcodePickViewHighlightStyleAsyncProvider = FrameworksBarcodePickViewHighlightStyleAsyncProvider(emitter: emitter, viewId: viewCreationParams.viewId)
        } else {
            barcodePickViewHighlightStyleAsyncProvider = nil
        }

        let barcodePickViewHighlightStyleCustomViewProvider: FrameworksBarcodePickViewHighlightStyleCustomViewProvider?
        if viewCreationParams.highlightType == .customView {
            barcodePickViewHighlightStyleCustomViewProvider = FrameworksBarcodePickViewHighlightStyleCustomViewProvider(emitter: emitter, viewId: viewCreationParams.viewId)
        } else {
            barcodePickViewHighlightStyleCustomViewProvider = nil
        }

        let barcodePickViewListener = FrameworksBarcodePickViewListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let barcodePickViewUiListener = FrameworksBarcodePickViewUiListener(emitter: emitter, viewId: viewCreationParams.viewId)

        let instance = FrameworksBarcodePickView(
            barcodePickActionListener: barcodePickActionListener,
            barcodePickAsyncMapperProductProviderCallback: barcodePickAsyncMapperProductProviderCallback,
            barcodePickListener: barcodePickListener,
            barcodePickScanningListener: barcodePickScanningListener,
            barcodePickViewHighlightStyleAsyncProvider: barcodePickViewHighlightStyleAsyncProvider,
            barcodePickViewHighlightStyleCustomViewProvider: barcodePickViewHighlightStyleCustomViewProvider,
            barcodePickViewListener: barcodePickViewListener,
            barcodePickViewUiListener: barcodePickViewUiListener,
            context: context
        )

        try instance.deserializeView(container: parent, context: context, viewCreationParams: viewCreationParams)
        return instance
    }

    public func dispose() {
        removeBarcodePickListener()
        removeBarcodePickScanningListener()
        removeBarcodePickViewListener()
        removeBarcodePickActionListener()
        removeBarcodePickViewUiListener()
        DispatchQueue.main.async { [weak self] in
            self?.view.removeFromSuperview()
        }
    }

    public func finishProductIdentifierForItems(barcodePickProductProviderCallbackItemsJson: String) {
        // Handle product identifier callback completion
        barcodePickAsyncMapperProductProviderCallback.finishMapIdentifiersForEvents(
            itemsJson: barcodePickProductProviderCallbackItemsJson
        )
    }

    public func finishPickAction(data: String, result: Bool) {
        barcodePickActionListener.finishPickAction(with: data, result: result)
    }

    public func finishBarcodePickViewHighlightStyleCustomViewProviderViewForRequest(
        requestId: Int,
        customView: UIView?,
        statusIconStyle: BarcodePickStatusIconStyle?
    ) {
        barcodePickViewHighlightStyleCustomViewProvider?.finishViewForRequest(
            requestId: requestId,
            view: customView,
            statusIconStyle: statusIconStyle
        )
    }

    public func finishBarcodePickViewHighlightStyleAsyncProviderStyleForRequest(
        requestId: Int,
        responseJson: String?
    ) {
        barcodePickViewHighlightStyleAsyncProvider?.finishStyleForRequest(
            requestId: requestId,
            responseJson: responseJson
        )
    }

}
