/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

open class FrameworksBarcodeFindTransformer: NSObject, BarcodeFindTransformer {
   
    private let emitter: Emitter
    
    private let onTransformBarcodeData = EventWithResult<String?>(event: Event(.transformBarcodeData))
    
    private let enabled = AtomicValue<Bool>(false)
    
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
        // Increase timeout to wait for result
        onTransformBarcodeData.timeout = 100
    }
    
    public func enable() {
        enabled.value = true
    }
    
    public func disable() {
        enabled.value = false
        cancel()
    }

    public func transformBarcodeData(_ data: String) -> String? {
        if !enabled.value {
            return data
        }
        
        return onTransformBarcodeData.emit(on: emitter, payload: ["data": data, "viewId": self.viewId]) ?? nil
    }

    public func submitResult(result: String?) {
        onTransformBarcodeData.unlock(value: result)
    }
    
    public func cancel() {
        onTransformBarcodeData.reset()
    }
}
