/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditFrameworksCore
import ScanditCaptureCore
import ScanditBarcodeCapture

public class BarcodeArHighlightParser {
    var emitter: Emitter
    
    init(emitter: Emitter) {
        self.emitter = emitter
    }

    func get(json: JSONValue, barcode: Barcode) -> (UIView & BarcodeArHighlight)? {
        guard let type = json.optionalString(forKey: "type") else {
            Log.error("Invalid JSON type.")
            return nil
        }

        switch type {
        case "barcodeArCircleHighlight":
            return getBarcodeArCircleHighlight(barcode: barcode, json: json)
        case "barcodeArRectangleHighlight":
            return getBarcodeArRectangleHighlight(barcode: barcode, json: json)
        case "barcodeArCustomHighlight":
            return BarcodeArCustomHighlight(barcode: barcode, emitter: emitter)
        default:
            Log.error("Not supported highlight type.", error: NSError(domain: "Type \(type)", code: -1))
            return nil
        }
    }

    func updateHighlight(_ highlight: BarcodeArHighlight, json: JSONValue) {
        switch highlight {
        case let circleHighlight as BarcodeArCircleHighlight:
            updateCircleHighlight(circleHighlight, json: json)
        case let rectangleHighlight as BarcodeArRectangleHighlight:
            updateRectangleHighlight(rectangleHighlight, json: json)
        default:
            break
        }
    }

    private func getBarcodeArCircleHighlight(barcode: Barcode, json: JSONValue) -> BarcodeArCircleHighlight? {
        guard let presetString = json.optionalString(forKey: "preset") else {
            Log.error("Invalid data for BarcodeArCircleHighlight.")
            return nil
        }

        var preset = BarcodeArCircleHighlightPreset.dot
        SDCBarcodeArCircleHighlightPresetFromJSONString(presetString, &preset)

        let highlight = BarcodeArCircleHighlight(barcode: barcode, preset: preset)
        updateCircleHighlight(highlight, json: json)
        return highlight
    }

    private func getBarcodeArRectangleHighlight(
        barcode: Barcode, json: JSONValue
    ) -> BarcodeArRectangleHighlight? {

        let highlight = BarcodeArRectangleHighlight(barcode: barcode)
        updateRectangleHighlight(highlight, json: json)
        return highlight
    }

    private func updateCircleHighlight(_ highlight: BarcodeArCircleHighlight, json: JSONValue) {
        do {
            let sizeValue = json.cgFloat(forKey: "size")

            if json.containsKey("icon") {
                let iconJson = json.getObjectAsString(forKey: "icon")
                highlight.icon = try ScanditIcon(fromJSONString: iconJson)
            }
            highlight.size =  sizeValue
            if json.containsKey("brush") {
                let brushString = json.getObjectAsString(forKey: "brush")
                if let brush = Brush(jsonString: brushString) {
                    highlight.brush = brush
                }
            }
        } catch {
            Log.error("Unable to parse the BarcodeArCircleHighlight from the provided json.", error: error)
        }
    }

    private func updateRectangleHighlight(_ highlight: BarcodeArRectangleHighlight, json: JSONValue) {

        do {
            if json.containsKey("icon") {
                let iconJson = json.getObjectAsString(forKey: "icon")
                highlight.icon = try ScanditIcon(fromJSONString: iconJson)
            }

            if json.containsKey("brush") {
                let brushString = json.getObjectAsString(forKey: "brush")
                if let brush = Brush(jsonString: brushString) {
                    highlight.brush = brush
                }
            }
        } catch {
            Log.error("Unable to parse the BarcodeArRectangleHighlight from the provided json.", error: error)
        }

    }
}
