//
//  HIDDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

#if os(OSX)

import Foundation
import IOKit.hid

final class HIDDeviceTransport: DeviceTransport {
	private var device: IOHIDDeviceRef

	init(device: IOHIDDeviceRef) {
		self.device = device
	}

	override func open() throws -> Bool {
		IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDDeviceOpen(device, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}

		opened()

		return true
	}

	override func close() {
		IOHIDDeviceClose(device, 0)

		closed()
	}

	override func writeData(data: NSData) throws -> Bool {
		let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
		let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, bytes, data.length)
		guard result == kIOReturnSuccess else {
			throw result
		}

		return true
	}
}

#endif


