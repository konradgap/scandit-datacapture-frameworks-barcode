/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

extension ScanditBarcodeCapture.BarcodePickState: Swift.CaseIterable {
    static public var allCases: [BarcodePickState] {
        [.ignore, .picked, .toPick, .unknown]
    }
}

struct BarcodePickViewHighlightStyleDefaults: DefaultsEncodable {
    private let rectangularStyle: BarcodePickViewHighlightStyleRectangular
    private let rectangularWithIconStyle: BarcodePickViewHighlightStyleRectangularWithIcons
    private let dotStyle: BarcodePickViewHighlightStyleDot
    private let dotWithIconStyle: BarcodePickViewHighlightStyleDotWithIcons
    private let customViewStyle: BarcodePickViewHighlightStyleCustomView

    func toEncodable() -> [String: Any?] {
        [
            "Rectangular": rectangularStyle.jsonString,
            "RectangularWithIcons": rectangularWithIconStyle.jsonString,
            "Dot": dotStyle.jsonString,
            "DotWithIcons": dotWithIconStyle.jsonString,
            "CustomView": customViewStyle.jsonString
        ]
    }

    static let shared: BarcodePickViewHighlightStyleDefaults = {
        return BarcodePickViewHighlightStyleDefaults(
            rectangularStyle: .init(),
            rectangularWithIconStyle: .init(),
            dotStyle: .init(),
            dotWithIconStyle: .init(),
            customViewStyle: .init()
        )
    }()
}
