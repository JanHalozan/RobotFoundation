//
//  HIDDeviceManager.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//

#if os(OSX)

import Foundation
import IOKit.hid

protocol HIDDeviceManagerDelegate: class {
	func HIDDeviceManagerFoundDevice(device: IOHIDDeviceRef)
}

final class HIDDeviceManager {
	private let manager: IOHIDManagerRef

	private var foundDevices = [IOHIDDeviceRef]()

	private weak var delegate: HIDDeviceManagerDelegate?

	init(delegate: HIDDeviceManagerDelegate) {
		manager = IOHIDManagerCreate(nil, 0).takeRetainedValue()
		self.delegate = delegate
	}

	deinit {
		IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
		IOHIDManagerClose(manager, 0)
	}

	func searchForDeviceWithProductID(productID: Int, vendorID: Int) throws {
		let matching = [kIOHIDVendorIDKey: vendorID, kIOHIDProductIDKey: productID]
		IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
		IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, other, device in

			let selfPointer = unsafeBitCast(context, HIDDeviceManager.self)
			selfPointer.foundDevice(device)

		}, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
		IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDManagerOpen(manager, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}
	}

	private func foundDevice(device: IOHIDDeviceRef) {
		foundDevices.append(device)
		delegate?.HIDDeviceManagerFoundDevice(device)
	}
}

#endif
