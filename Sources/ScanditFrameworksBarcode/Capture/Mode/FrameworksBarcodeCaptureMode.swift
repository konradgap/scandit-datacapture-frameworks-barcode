/*
* This file is part of the Scandit Data Capture SDK
*
* Copyright (C) 2025- Scandit AG. All rights reserved.
*/

import ScanditBarcodeCapture
import ScanditFrameworksCore

public class FrameworksBarcodeCaptureMode: FrameworksBaseMode {
   private let listener: FrameworksBarcodeCaptureListener
   private let captureContext: DefaultFrameworksCaptureContext
   private let deserializer: BarcodeCaptureDeserializer

   private var _modeId: Int = -1
   private var _parentId: Int? = nil

   public var modeId: Int {
       return _modeId
   }

   public var parentId: Int? {
       return _parentId
   }

   public private(set) var mode: BarcodeCapture!

   public var isEnabled: Bool {
       get {
           return mode.isEnabled
       }
       set {
           mode.isEnabled = newValue
       }
   }

   public init(
       listener: FrameworksBarcodeCaptureListener,
       captureContext: DefaultFrameworksCaptureContext,
       deserializer: BarcodeCaptureDeserializer = BarcodeCaptureDeserializer()
   ) {
       self.listener = listener
       self.captureContext = captureContext
       self.deserializer = deserializer
   }

   private func deserializeMode(
       dataCaptureContext: DataCaptureContext,
       creationData: BarcodeCaptureModeCreationData
   ) throws {
       mode = try deserializer.mode(fromJSONString: creationData.modeJson, with: dataCaptureContext)
       captureContext.addMode(mode: mode)

       if creationData.hasListener {
           mode.addListener(listener)
       }

       mode.isEnabled = creationData.isEnabled
       _modeId = creationData.modeId
       _parentId = creationData.parentId
   }

   public func dispose() {
       listener.reset()
       mode.removeListener(listener)
       captureContext.removeMode(mode: mode)
   }

   public func addListener() {
       mode.addListener(listener)
   }

   public func removeListener() {
       mode.removeListener(listener)
   }

   public func finishDidUpdateSession(enabled: Bool) {
       listener.finishDidUpdateSession(enabled: enabled)
   }

   public func finishDidScan(enabled: Bool) {
       listener.finishDidScan(enabled: enabled)
   }

   public func applySettings(modeSettingsJson: String) throws {
       let settings = try deserializer.settings(fromJSONString: modeSettingsJson)
       mode.apply(settings)
   }

   public func updateModeFromJson(modeJson: String) throws {
       try deserializer.updateMode(mode, fromJSONString: modeJson)
   }

   public func updateFeedback(feedbackJson: String) throws {
       mode.feedback = try BarcodeCaptureFeedback(fromJSONString: feedbackJson)
   }

   // MARK: - Factory Method

   public static func create(
       emitter: Emitter,
       captureContext: DefaultFrameworksCaptureContext,
       creationData: BarcodeCaptureModeCreationData,
       dataCaptureContext: DataCaptureContext,
       cachedCaptureSession: AtomicValue<FrameworksBarcodeCaptureSession?>
   ) throws -> FrameworksBarcodeCaptureMode {
       let listener = FrameworksBarcodeCaptureListener(emitter: emitter, modeId: creationData.modeId, cachedCaptureSession: cachedCaptureSession)
       let mode = FrameworksBarcodeCaptureMode(
           listener: listener,
           captureContext: captureContext
       )

       try mode.deserializeMode(dataCaptureContext: dataCaptureContext, creationData: creationData)
       return mode
   }
}
