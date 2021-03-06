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
	private let manager: IOHIDManager
	private var foundDevices = Set<MetaDevice>()

	private unowned var client: RobotDeviceSourceClient

	public init(client: RobotDeviceSourceClient) {
		manager = IOHIDManagerCreate(nil, 0)
		self.client = client
	}

	deinit {
		IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
		IOHIDManagerClose(manager, 0)
	}

	public func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		do {
			try searchForDeviceWithCriteria(searchCriteria)
		} catch {
			print("Could not begin search for HID devices: \(error)")
		}
	}

	public func searchForDeviceWithCriteria(_ criteria: [RobotDeviceDescriptor]) throws {
		var matchingDicts = [CFDictionary]()

		for c in criteria {
			let matching = [kIOHIDVendorIDKey: c.vendorID, kIOHIDProductIDKey: c.productID]
			matchingDicts.append(matching as CFDictionary)
		}

		IOHIDManagerSetDeviceMatchingMultiple(manager, matchingDicts as CFArray)
		IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, other, device in

			let selfPointer = unsafeBitCast(context, to: HIDDeviceSource.self)
			selfPointer.foundDevice(device)

		}, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
		IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, other, device in

			let selfPointer = unsafeBitCast(context, to: HIDDeviceSource.self)
			selfPointer.lostDevice(device)

		}, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
		IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

		let result = IOHIDManagerOpen(manager, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}
	}

	private func foundDevice(_ device: IOHIDDevice) {
		let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "HID Device"
		let uniqueIdentifier = IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String ?? ""

		let robotDevice = MetaDevice(type: .hidDevice, deviceClass: .EV3, uniqueIdentifier: uniqueIdentifier, name: name)
		foundDevices.insert(robotDevice)
		client.robotDeviceSourceDidFindDevice(robotDevice)
	}

	private func lostDevice(_ device: IOHIDDevice) {
		if let robotDevice = findHIDRobotDevice(device) {
			client.robotDeviceSourceDidLoseDevice(robotDevice)
		}
	}

	private func findHIDRobotDevice(_ deviceRef: IOHIDDevice) -> MetaDevice? {
		let uniqueIdentifier = IOHIDDeviceGetProperty(deviceRef, kIOHIDSerialNumberKey as CFString) as? String ?? ""

		for foundDevice in foundDevices {
			if case RobotDeviceType.hidDevice = foundDevice.type {
				if foundDevice.uniqueIdentifier == uniqueIdentifier {
					return foundDevice
				}
			}
		}

		return nil
	}
}

#endif
