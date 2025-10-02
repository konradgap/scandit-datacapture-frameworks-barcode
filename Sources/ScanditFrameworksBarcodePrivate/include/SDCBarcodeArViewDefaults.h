/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <ScanditCaptureCore/SDCBase.h>
#import <ScanditBarcodeCapture/SDCBarcodeArCircleHighlight.h>
#import <ScanditCaptureCore/SDCAnchor.h>
#import <ScanditCaptureCore/SDCCamera.h>
#import <ScanditBarcodeCapture/SDCBarcodeArPopoverAnnotation.h>
#import <ScanditBarcodeCapture/SDCBarcodeArInfoAnnotation.h>
#import <ScanditBarcodeCapture/SDCBarcodeArInfoAnnotationBodyComponent.h>
#import <ScanditBarcodeCapture/SDCBarcodeArStatusIconAnnotation.h>

NS_ASSUME_NONNULL_BEGIN

@class SDCScanditIcon;
@class SDCBrush;

SDC_EXPORTED_SYMBOL
NS_SWIFT_NAME(BarcodeArViewDefaults)
@interface SDCBarcodeArViewDefaults : NSObject

// clang-format off
@property (class, nonatomic, assign, readonly) BOOL defaultHapticsEnabled;
@property (class, nonatomic, assign, readonly) BOOL defaultSoundEnabled;

@property (class, nonatomic, assign, readonly) BOOL defaultShouldShowTorchControl;
@property (class, nonatomic, assign, readonly) BOOL defaultShouldShowZoomControl;
@property (class, nonatomic, assign, readonly) BOOL defaultShouldShowCameraSwitchControl;
@property (class, nonatomic, assign, readonly) BOOL defaultShouldShowMacroModeControl;
@property (class, nonatomic, assign, readonly) SDCCameraPosition defaultCameraPosition;
@property (class, nonatomic, assign, readonly) SDCAnchor defaultTorchControlPosition;
@property (class, nonatomic, assign, readonly) SDCAnchor defaultZoomControlPosition;
@property (class, nonatomic, assign, readonly) SDCAnchor defaultCameraSwitchControlPosition;
@property (class, nonatomic, assign, readonly) SDCAnchor defaultMacroModeControlPosition;

@property (class, nonatomic, readonly) SDCBrush *defaultRectangleHighlightBrush;
@property (class, nonatomic, nullable, readonly) SDCScanditIcon *defaultRectangleHighlightIcon;

@property (class, nonatomic, readonly) BOOL defaultHighlightIsPulsing;

@property (class, nonatomic, readonly) SDCBarcodeArStatusIconAnnotationAnchor defaultStatusIconAnnotationAnchor;
@property (class, nonatomic, readonly) SDCBarcodeArAnnotationTrigger defaultStatusIconAnnotationTrigger;
@property (class, nonatomic, readonly) BOOL defaultStatusIconAnnotationHasTip;
@property (class, nonatomic, readonly) SDCScanditIcon *defaultStatusIconAnnotationIcon;
@property (class, nonatomic, readonly, nullable) NSString *defaultStatusIconAnnotationText;
@property (class, nonatomic, readonly) UIColor *defaultStatusIconAnnotationBackgroundColor;
@property (class, nonatomic, readonly) UIColor *defaultStatusIconAnnotationIconTextColor;
@property (class, nonatomic, readonly) UIFont *defaultStatusIconAnnotationLabelFont;

@property (class, nonatomic, readonly) SDCBarcodeArAnnotationTrigger defaultPopoverAnnotationTrigger;
@property (class, nonatomic, readonly) BOOL defaultPopoverAnnotationIsEntirePopoverTappable;
@property (class, nonatomic, readonly) BOOL defaultPopoverAnnotationButtonEnabled;
@property (class, nonatomic, readonly) UIFont *defaultPopoverAnnotationButtonFont;
@property (class, nonatomic, readonly) UIColor *defaultPopoverAnnotationButtonTextColor;
@property (class, nonatomic, readonly) SDCBarcodeArPopoverAnnotationAnchor defaultPopoverAnnotationAnchor;

@property (class, nonatomic, readonly) SDCBarcodeArAnnotationTrigger defaultInfoAnnotationTrigger;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationBackgroundColor;
@property (class, nonatomic, readonly) BOOL defaultInfoAnnotationHasTip;
@property (class, nonatomic, readonly) BOOL defaultInfoAnnotationIsEntireAnnotationTappable;
@property (class, nonatomic, readonly) SDCBarcodeArInfoAnnotationAnchor defaultInfoAnnotationAnchor;
@property (class, nonatomic, readonly) SDCBarcodeArInfoAnnotationWidthPreset defaultInfoAnnotationWidth;

@property (class, nonatomic, nullable, readonly) SDCScanditIcon *defaultInfoAnnotationHeaderIcon;
@property (class, nonatomic, nullable, readonly) NSString *defaultInfoAnnotationHeaderText;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationHeaderBackgroundColor;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationHeaderTextColor;
@property (class, nonatomic, readonly) UIFont *defaultInfoAnnotationHeaderFont;

@property (class, nonatomic, nullable, readonly) SDCScanditIcon *defaultInfoAnnotationFooterIcon;
@property (class, nonatomic, nullable, readonly) NSString *defaultInfoAnnotationFooterText;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationFooterBackgroundColor;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationFooterTextColor;
@property (class, nonatomic, readonly) UIFont *defaultInfoAnnotationFooterFont;

@property (class, nonatomic, readonly) BOOL defaultInfoAnnotationBodyComponentIsLeftIconTappable;
@property (class, nonatomic, readonly) BOOL defaultInfoAnnotationBodyComponentIsRightIconTappable;
@property (class, nonatomic, nullable, readonly) NSString *defaultInfoAnnotationBodyComponentText;
@property (class, nonatomic, nullable, readonly) NSAttributedString *defaultInfoAnnotationBodyComponentStyledText;
@property (class, nonatomic, readonly) NSTextAlignment defaultInfoAnnotationBodyComponentTextAlignment;
@property (class, nonatomic, nullable, readonly) SDCScanditIcon *defaultInfoAnnotationBodyComponentLeftIcon;
@property (class, nonatomic, nullable, readonly) SDCScanditIcon *defaultInfoAnnotationBodyComponentRightIcon;
@property (class, nonatomic, readonly) UIFont *defaultInfoAnnotationBodyComponentFont;
@property (class, nonatomic, readonly) UIColor *defaultInfoAnnotationBodyComponentTextColor;
//clang-format on

- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (CGFloat)defaultCircleHighlightSizeForPreset:(SDCBarcodeArCircleHighlightPreset)preset;
+ (SDCBrush *)defaultCircleHighlightBrushForPreset:(SDCBarcodeArCircleHighlightPreset)preset;
+ (nullable SDCScanditIcon *)defaultCircleHighlightIconForPreset:
    (SDCBarcodeArCircleHighlightPreset)preset;

@end

NS_ASSUME_NONNULL_END
