/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditCaptureCore
import ScanditFrameworksCore

extension SDCBarcodeFilterHighlightType {
    var jsonString: String {
        switch self {
        case .brush:
            return "brush"
        @unknown default:
            return "brush"
        }
    }
}

public struct BarcodeFilterHighlightSettingsDefaults : DefaultsEncodable {
    private let filterSettings: BarcodeFilterHighlightSettings

    fileprivate init(filterSettings: BarcodeFilterHighlightSettings) {
        self.filterSettings = filterSettings
    }

    public func toEncodable() -> [String: Any?] {
        var encodableBrush: [String: Any?]?
        if let brush = filterSettings.brush {
            encodableBrush =  EncodableBrush(brush: brush).toEncodable()
        }
        
        return [
            "brush": encodableBrush,
            "highlightType": filterSettings.highlightType.jsonString
        ]
    }

    public static func create(filterSettings: BarcodeFilterHighlightSettings?) -> [String: Any?]? {
        guard let filterSettings = filterSettings else { return nil }
        return BarcodeFilterHighlightSettingsDefaults(filterSettings: filterSettings).toEncodable()
    }
}
