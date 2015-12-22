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
	private var foundDevices = Set<MetaDevice>()

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
		IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, other, device in

			let selfPointer = unsafeBitCast(context, HIDDeviceSource.self)
			selfPointer.lostDevice(device)

		}, UnsafeMutablePointer<Void>(unsafeAddressOf(self)))
		IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDManagerOpen(manager, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}
	}

	private func foundDevice(device: IOHIDDeviceRef) {
		let robotDevice = MetaDevice(hidDevice: device)
		foundDevices.insert(robotDevice)
		client.robotDeviceSourceDidFindDevice(robotDevice)
	}

	private func lostDevice(device: IOHIDDeviceRef) {
		if let robotDevice = findHIDRobotDevice(device) {
			client.robotDeviceSourceDidLoseDevice(robotDevice)
		}
	}

	private func findHIDRobotDevice(deviceRef: IOHIDDeviceRef) -> MetaDevice? {
		for foundDevice in foundDevices {
			if case RobotDeviceTypeInternal.HIDDevice(let dev) = foundDevice.internalType {
				if dev === deviceRef {
					return foundDevice
				}
			}
		}

		return nil
	}
}

#endif
