/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore
import UIKit

struct AdvancedOverlayViewData {
    let widgetData: Data?
    let trackedBarcodeId: Int
    let sessionFrameSequenceId: Int?
    let dataCaptureViewId: Int

    init(widgetData: Data?, trackedBarcodeId: Int, sessionFrameSequenceId: Int?, dataCaptureViewId: Int) {
        self.widgetData = widgetData
        self.trackedBarcodeId = trackedBarcodeId
        self.sessionFrameSequenceId = sessionFrameSequenceId
        self.dataCaptureViewId = dataCaptureViewId
    }

    init(dictionary: [String: Any?]) {
        self.init(widgetData: dictionary["widget"] as? Data,
                  trackedBarcodeId: dictionary["trackedBarcodeIdentifier"] as! Int,
                  sessionFrameSequenceId: dictionary["sessionFrameSequenceID"] as? Int,
                  dataCaptureViewId: dictionary["dataCaptureViewId"] as! Int
        )
    }
}
