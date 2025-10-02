/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

final class ReadWriteCoordinator {
    private let queue = DispatchQueue(label: "com.scandit.frameworks.barcodepickactionlistener.ReadWriteCoordinator",
                                      attributes: .concurrent)

    public func read<R>(_ fn: () -> R)
        -> R
    {
        var result: R?
        queue.sync {
            result = fn()
        }
        return result!
    }

    public func blockingWrite<R>(_ fn: () -> R)
        -> R
    {
        var result: R?
        queue.sync(flags: .barrier) {
            result = fn()
        }
        return result!
    }
}

public enum BarcodePickEvent: String, CaseIterable {
    case pick = "BarcodePickActionListener.didPick"
    case unpick = "BarcodePickActionListener.didUnpick"
    case onProductIdentifierForItems = "BarcodePickAsyncMapperProductProviderCallback.onProductIdentifierForItems"
}

fileprivate extension Emitter {
    func emit(_ event: BarcodePickEvent, payload: [String: Any?]) {
        emit(name: event.rawValue, payload: payload)
    }
}

open class FrameworksBarcodePickActionListener: NSObject, BarcodePickActionListener {
    private let emitter: Emitter
    private let viewId: Int
    private var events: [String: (Bool) -> Void] = [:]
    private let coordinator = ReadWriteCoordinator()

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func didPickItem(withData data: String, completionHandler: @escaping (Bool) -> Void) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickEvent.pick.rawValue) else { return }
        coordinator.blockingWrite {
            events[data] = completionHandler
        }
        emitter.emit(.pick, payload: [
            "itemData": data,
            "viewId": self.viewId
        ])
    }

    public func didUnpickItem(withData data: String, completionHandler: @escaping (Bool) -> Void) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickEvent.unpick.rawValue) else { return }
        coordinator.blockingWrite {
            events[data] = completionHandler
        }
        emitter.emit(.unpick, payload: [
            "itemData": data,
            "viewId": self.viewId
        ])
    }

    public func finishPickAction(with data: String, result: Bool) {
        let callback = coordinator.read {
            events.removeValue(forKey: data)
        }
        callback?(result)
    }
}
