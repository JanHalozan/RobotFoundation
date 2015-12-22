//
//  HIDDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//

#if os(OSX)

import Foundation
import IOKit.hid

public final class HIDDeviceSource: RobotDeviceSource {
	private let manager: IOHIDManagerRef

	private unowned var client: RobotDeviceSourceClient

	public init(client: RobotDeviceSourceClient) {
		manager = IOHIDManagerCreate(nil, 0).takeRetainedValue()
		self.client = client
	}

	deinit {
		IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
		IOHIDManagerClose(manager, 0)
	}

	public func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		do {
			try searchForDeviceWithCriteria(searchCriteria)
		} catch {
			print("Could not begin search for HID devices: \(error)")
		}
	}

	public func searchForDeviceWithCriteria(criteria: [RobotDeviceDescriptor]) throws {
		var matchingDicts = [CFDictionary]()

		for c in criteria {
			let matching = [kIOHIDVendorIDKey: c.vendorID, kIOHIDProductIDKey: c.productID]
			matchingDicts.append(matching)
		}

		IOHIDManagerSetDeviceMatchingMultiple(manager, matchingDicts)
		IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, other, device in

			let selfPointer = unsafeBitCast(context, HIDDeviceSource.self)
			selfPointer.foundDevice(device)

		}, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
		IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDManagerOpen(manager, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}
	}

	private func foundDevice(device: IOHIDDeviceRef) {
		client.robotDeviceSourceDidFindDevice(RobotDevice(hidDevice: device))
	}
}

#endif
