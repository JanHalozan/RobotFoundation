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

	var inputReportBuffer = [UInt8](count: 128, repeatedValue: 0)

	init(device: IOHIDDeviceRef) {
		self.device = device
	}

	override func open() throws {
		IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
		IOHIDDeviceRegisterInputReportCallback(device, &inputReportBuffer, inputReportBuffer.count, { context, result, interface, reportType, index, bytes, length in

			let selfPointer = unsafeBitCast(context, HIDDeviceTransport.self)
			selfPointer.receivedReport()

		}, UnsafeMutablePointer(unsafeAddressOf(self)))
		let result = IOHIDDeviceOpen(device, 0)
		guard result == kIOReturnSuccess else {
			throw result
		}

		opened()
	}

	private func receivedReport() {
		let data = NSData(bytes: &inputReportBuffer, length: inputReportBuffer.count)
		receivedData(data)
	}

	override func close() {
		IOHIDDeviceClose(device, 0)

		closed()
	}

	override func writeData(data: NSData) throws {
		let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
		let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, bytes, data.length)
		guard result == kIOReturnSuccess else {
			throw result
		}
	}
}

#endif


