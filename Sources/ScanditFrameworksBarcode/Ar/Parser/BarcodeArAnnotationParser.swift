/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation
import UIKit
import ScanditCaptureCore
import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum FrameworksBarcodeArAnnotationEvents: String, CaseIterable {
    case didTapPopover = "BarcodeArPopoverAnnotationListener.didTapPopover"
    case didTapPopoverButton = "BarcodeArPopoverAnnotationListener.didTapPopoverButton"
    case didTapInfoAnnotationFooter = "BarcodeArInfoAnnotationListener.didTapInfoAnnotationFooter"
    case didTapInfoAnnotationHeader = "BarcodeArInfoAnnotationListener.didTapInfoAnnotationHeader"
    case didTapInfoAnnotation = "BarcodeArInfoAnnotationListener.didTapInfoAnnotation"
    case didTapInfoAnnotationLeftIcon = "BarcodeArInfoAnnotationListener.didTapInfoAnnotationLeftIcon"
    case didTapInfoAnnotationRightIcon = "BarcodeArInfoAnnotationListener.didTapInfoAnnotationRightIcon"
}

public class BarcodeArAnnotationParser {
    private var infoAnnotationDelegate: FrameworksInfoAnnotationDelegate?
    private var popoverAnnotationDelegate: FrameworksPopoverAnnotationDelegate?
    private var cache: BarcodeArAugmentationsCache?

    init() {
        // Initialize without delegates - they will be set later
    }

    func setDelegates(
        infoAnnotationDelegate: FrameworksInfoAnnotationDelegate,
        popoverAnnotationDelegate: FrameworksPopoverAnnotationDelegate,
        cache: BarcodeArAugmentationsCache
    ) {
        self.infoAnnotationDelegate = infoAnnotationDelegate
        self.popoverAnnotationDelegate = popoverAnnotationDelegate
        self.cache = cache
    }

    func get(json: JSONValue, barcode: Barcode) -> (UIView & BarcodeArAnnotation)? {
        guard let type = json.optionalString(forKey: "type") else {
            Log.error("Missing type in JSON.")
            return nil
        }

        switch type {
        case "barcodeArInfoAnnotation":
            return getInfoAnnotation(barcode: barcode, json: json)
        case "barcodeArPopoverAnnotation":
            return getPopoverAnnotation(barcode: barcode, json: json)
        case "barcodeArStatusIconAnnotation":
            return getStatusIconAnnotation(barcode: barcode, json: json)
        default:
            Log.error("Not supported annotation type.", error: NSError(domain: "Type \(type)", code: -1))
            return nil
        }
    }

    func updateAnnotation(_ annotation: BarcodeArAnnotation, json: JSONValue) {
        switch annotation {
        case let infoAnnotation as BarcodeArInfoAnnotation:
            guard let barcodeId = json.optionalString(forKey: "barcodeId") else {
                Log.error("Missing barcodeId in JSON.")
                return
            }
            updateInfoAnnotation(infoAnnotation, json, barcodeId)
        case let statusIconAnnotation as BarcodeArStatusIconAnnotation:
            let iconJson = json.getObjectAsString(forKey: "icon")
            updateStatusIconAnnotation(statusIconAnnotation, iconJson, json)
        case let popoverAnnotation as BarcodeArPopoverAnnotation:
            updatePopoverAnnotation(popoverAnnotation, json, popoverAnnotation.barcode)
        default:
            Log.error("Unsupported annotation type")
        }
    }

    func updateBarcodeArPopoverButton(_ annotation: BarcodeArPopoverAnnotation, json: JSONValue) {
        guard let index = json.optionalInt(forKey: "index") else {
            Log.error("Invalid index received when trying to update the updateBarcodeArPopoverButton.")
            return
        }

        if  index < 0 {
            Log.error(
                "Invalid index received when trying to update the updateBarcodeArPopoverButton.",
                error: NSError(domain: "Index \(index)", code: -1)
            )
            return
        }

        if index > annotation.buttons.count - 1 {
            Log.error(
                "Invalid index received when trying to update the updateBarcodeArPopoverButton",
                error: NSError(domain: "Buttons Size \(annotation.buttons.count), Index \(index)", code: -1)
            )
            return
        }

        let button = annotation.buttons[index]
        if let textColorHex = json.optionalString(forKey: "textColor"),
           let textColor = UIColor(sdcHexString: textColorHex) {
            button.textColor = textColor
        }
        button.font = json.getFont(forSizeKey: "textSize", andFamilyKey: "fontFamily")
        button.isEnabled = json.bool(forKey: "enabled", default: false)
    }
}

// MARK: - Barcode Ar Info Annotation

private extension BarcodeArAnnotationParser {

    private func getInfoAnnotation(barcode: Barcode, json: JSONValue) -> BarcodeArInfoAnnotation? {
        let annotation = BarcodeArInfoAnnotation(barcode: barcode)

        updateInfoAnnotation(annotation, json, barcode.uniqueId)

        return annotation
    }

    private func updateInfoAnnotation(
        _ annotation: BarcodeArInfoAnnotation,
        _ json: JSONValue,
        _ barcodeId: String
    ) {
        annotation.hasTip = json.bool(forKey: "hasTip", default: false)
        annotation.isEntireAnnotationTappable = json.bool(forKey: "isEntireAnnotationTappable", default: false)
        if let anchorJson = json.optionalString(forKey: "anchor") {
            var anchor = BarcodeArInfoAnnotationAnchor.bottom
            SDCBarcodeArInfoAnnotationAnchorFromJSONString(anchorJson, &anchor)
            annotation.anchor = anchor
        }

        if let widthJson = json.optionalString(forKey: "width") {
            var width = BarcodeArInfoAnnotationWidthPreset.small
            SDCBarcodeArInfoAnnotationWidthPresetFromJSONString(widthJson, &width)
            annotation.width = width
        }

        if json.containsKey("header") {
            annotation.header = parseInfoAnnotationHeader(json.object(forKey: "header"))
        }

        if json.containsKey("footer") {
            annotation.footer = parseInfoAnnotationFooter(json.object(forKey: "footer"))
        }

        let bodyComponentsJson = json.array(forKey: "body")
        var bodyComponents = [BarcodeArInfoAnnotationBodyComponent]()
        for index in 0..<bodyComponentsJson.count() {
            let bodyJson = bodyComponentsJson.atIndex(index)
            if let component = getBarcodeArInfoAnnotationBodyComponent(json: bodyJson) {
                bodyComponents.append(component)
            }
        }
        annotation.body = bodyComponents

        if json.bool(forKey: "hasListener", default: false) {
            if annotation.delegate == nil {
                annotation.delegate = self.infoAnnotationDelegate
            }
        } else {
            annotation.delegate = nil
        }

        var trigger = BarcodeArAnnotationTrigger.highlightTap
        SDCBarcodeArAnnotationTriggerFromJSONString(json.string(forKey: "annotationTrigger"), &trigger)
        annotation.annotationTrigger = trigger
    }

    private func parseInfoAnnotationHeader(_ json: JSONValue) -> BarcodeArInfoAnnotationHeader {
        let annotationHeader = BarcodeArInfoAnnotationHeader()
        do {

            if json.containsKey("icon") {
                let headerIconJson = json.getObjectAsString(forKey: "icon")
                annotationHeader.icon = try ScanditIcon(fromJSONString: headerIconJson)
            }
            annotationHeader.text = json.optionalString(forKey: "text")
            if let headerBackgroundColorHex = json.optionalString(forKey: "backgroundColor"),
               let headerBackgroundColor = UIColor(sdcHexString: headerBackgroundColorHex) {
                annotationHeader.backgroundColor = headerBackgroundColor
            }
            if let headerTextColorHex = json.optionalString(forKey: "textColor"),
               let headerTextColor = UIColor(sdcHexString: headerTextColorHex) {
                annotationHeader.textColor = headerTextColor
            }
            annotationHeader.font = json.getFont(forSizeKey: "textSize", andFamilyKey: "fontFamily")
        } catch {
            Log.error("Unable to parse the BarcodeArInfoAnnotation header from the given json.", error: error)
        }
        return annotationHeader
    }

    private func parseInfoAnnotationFooter(_ json: JSONValue) -> BarcodeArInfoAnnotationFooter {
        let annotationFooter = BarcodeArInfoAnnotationFooter()
        do {

            if json.containsKey("icon") {
                let footerIconJson = json.getObjectAsString(forKey: "icon")
                annotationFooter.icon = try ScanditIcon(fromJSONString: footerIconJson)
            }
            annotationFooter.text = json.optionalString(forKey: "text")
            if let footerBackgroundColorHex = json.optionalString(forKey: "backgroundColor"),
               let footerBackgroundColor = UIColor(sdcHexString: footerBackgroundColorHex) {
                annotationFooter.backgroundColor = footerBackgroundColor
            }
            if let footerTextColorHex = json.optionalString(forKey: "textColor"),
               let footerTextColor = UIColor(sdcHexString: footerTextColorHex) {
                annotationFooter.textColor = footerTextColor
            }
            annotationFooter.font = json.getFont(forSizeKey: "textSize", andFamilyKey: "fontFamily")
        } catch {
            Log.error("Unable to parse the BarcodeArInfoAnnotation footer from the given json.", error: error)
        }
        return annotationFooter
    }

    private func getBarcodeArInfoAnnotationBodyComponent(
        json: JSONValue
    ) -> BarcodeArInfoAnnotationBodyComponent? {
        do {
            let bodyComponent = BarcodeArInfoAnnotationBodyComponent()
            bodyComponent.text = json.optionalString(forKey: "text")
            if let textColorHex = json.optionalString(forKey: "textColor"),
               let textColor = UIColor(sdcHexString: textColorHex) {
                bodyComponent.textColor = textColor
            }
            bodyComponent.textAlignment = json.getTextAlignment(forKey: "textAlign")
            bodyComponent.isLeftIconTappable = json.bool(forKey: "isLeftIconTappable", default: false)
            if json.containsKey("leftIcon") {
                let leftIconJson = json.getObjectAsString(forKey: "leftIcon")
                bodyComponent.leftIcon = try ScanditIcon(fromJSONString: leftIconJson)
            }
            bodyComponent.isRightIconTappable = json.bool(forKey: "isRightIconTappable", default: false)
            if json.containsKey("rightIcon") {
                let rightIconJson = json.getObjectAsString(forKey: "rightIcon")
                bodyComponent.rightIcon =  try ScanditIcon(fromJSONString: rightIconJson)
            }
            return bodyComponent
        } catch {
            Log.error("Unable to parse the BarcodeArInfoAnnotationBodyElement from the provided json.", error: error)
            return nil
        }
    }
}

// MARK: - Barcode Ar Popover Annotation

private extension BarcodeArAnnotationParser {

    private func getPopoverAnnotation(barcode: Barcode, json: JSONValue) -> BarcodeArPopoverAnnotation? {
        do {
            let annotationButtons = json.array(forKey: "buttons")

            var buttons: [BarcodeArPopoverAnnotationButton] = []

            for index in 0..<annotationButtons.count() {
                let buttonJson = annotationButtons.atIndex(index)

                let iconJson = buttonJson.getObjectAsString(forKey: "icon")
                let text = buttonJson.string(forKey: "text")

                let button = BarcodeArPopoverAnnotationButton(
                    icon: try ScanditIcon(fromJSONString: iconJson),
                    text: text
                )
                updatePopoverButton(json, button)
                buttons.append(button)
            }

            let annotation = BarcodeArPopoverAnnotation(barcode: barcode, buttons: buttons)
            updatePopoverAnnotation(annotation, json, barcode)

            return annotation
        } catch {
            Log.error("Unable to parse the BarcodeArPopoverAnnotation from the provided json.", error: error)
            return nil
        }
    }

    private func updatePopoverAnnotation(
        _ annotation: BarcodeArPopoverAnnotation,
        _ json: JSONValue,
        _ barcode: Barcode
    ) {
        annotation.isEntirePopoverTappable = json.bool(forKey: "isEntirePopoverTappable", default: false)
        if json.bool(forKey: "hasListener", default: false) && annotation.delegate == nil {
            if annotation.delegate == nil {
                annotation.delegate = self.popoverAnnotationDelegate as! any BarcodeArPopoverAnnotationDelegate
            }
        } else {
            annotation.delegate = nil
        }
        var trigger = BarcodeArAnnotationTrigger.highlightTap
        SDCBarcodeArAnnotationTriggerFromJSONString(json.string(forKey: "annotationTrigger"), &trigger)
        annotation.annotationTrigger = trigger
    }

    private func updatePopoverButton(_ json: JSONValue, _ button: BarcodeArPopoverAnnotationButton) {
        if let textColorHex = json.optionalString(forKey: "textColor"),
           let textColor = UIColor(sdcHexString: textColorHex) {
            button.textColor = textColor
        }

        button.font = json.getFont(forSizeKey: "textSize", andFamilyKey: "fontFamily")
        button.isEnabled = json.bool(forKey: "enabled", default: false)
    }
}

// MARK: - Barcode Ar Status Icon Annotation

private extension BarcodeArAnnotationParser {

    private func getStatusIconAnnotation(barcode: Barcode, json: JSONValue) -> BarcodeArStatusIconAnnotation? {
        if json.containsKey("icon") == false {
            Log.error("Missing icon in status icon annotation JSON.")
            return nil
        }
        let annotation = BarcodeArStatusIconAnnotation(barcode: barcode)
        updateStatusIconAnnotation(annotation, json.getObjectAsString(forKey: "icon"), json)
        return annotation
    }

    private func updateStatusIconAnnotation(
        _ annotation: BarcodeArStatusIconAnnotation,
        _ iconJson: String,
        _ json: JSONValue
    ) {
        do {
            annotation.icon = try ScanditIcon(fromJSONString: iconJson)
            annotation.hasTip = json.bool(forKey: "hasTip", default: false)
            annotation.text = json.optionalString(forKey: "text")
            if let textColorHex = json.optionalString(forKey: "textColor"),
               let textColor = UIColor(sdcHexString: textColorHex) {
                annotation.textColor = textColor
            }
            if let backgroundColorHex = json.optionalString(forKey: "backgroundColor"),
               let backgroundColor = UIColor(sdcHexString: backgroundColorHex) {
                annotation.backgroundColor = backgroundColor
            }

            var trigger = BarcodeArAnnotationTrigger.highlightTap
            SDCBarcodeArAnnotationTriggerFromJSONString(json.string(forKey: "annotationTrigger"), &trigger)
            annotation.annotationTrigger = trigger
        } catch {
            Log.error("Unable to parse the BarcodeArStatusIconAnnotation from the provided json.", error: error)
        }
    }
}
