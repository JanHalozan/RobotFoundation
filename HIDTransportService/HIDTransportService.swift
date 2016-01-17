//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOKit.hid

final class HIDTransportService : NSObject, XPCTransportServiceProtocol {
	private var device: IOHIDDevice?
	private var activeClients = 0
	private var inputReportBuffer = [UInt8](count: 1024, repeatedValue: 0)

	private var writeSemaphore = dispatch_semaphore_create(0)
	private var receivedData: NSData?

	private let connection: NSXPCConnection

	init(connection: NSXPCConnection) {
		self.connection = connection
		super.init()
	}

	private var currentIdentifier: String? {
		assert(NSThread.isMainThread())

		guard let device = device else {
			return nil
		}

		guard let property = IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey) else {
			return nil
		}

		return property.takeUnretainedValue() as? String
	}

	func open(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyOpenWithIdentifier(identifier, handler: handler)
		}
	}

	private func actuallyOpenWithIdentifier(identifier: NSString, handler: Int -> ()) {
		assert(NSThread.isMainThread())

		if currentIdentifier == nil {
			assert(activeClients == 0)
			activeClients += 1
			openNewDevice(identifier, handler: handler)
		} else if currentIdentifier! == identifier {
			activeClients += 1
		} else {
			debugPrint("Tried to open a device while one was already open.")
			handler(Int(1))
			return
		}

		handler(Int(kIOReturnSuccess))
	}

	private func openNewDevice(identifier: NSString, handler: Int -> ()) {
		let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
		matching[kIOHIDSerialNumberKey] = identifier

		let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching as CFDictionaryRef)

		guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service)?.takeRetainedValue() else {
			handler(1)
			return
		}

		device = hidDevice

		IOHIDDeviceRegisterInputReportCallback(device, &inputReportBuffer, inputReportBuffer.count, { context, result, interface, reportType, index, bytes, length in

			let selfPointer = unsafeBitCast(context, HIDTransportService.self)
			selfPointer.receivedReport()

		}, UnsafeMutablePointer(unsafeAddressOf(self)))
		IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDDeviceOpen(device, 0)
		guard result == kIOReturnSuccess else {
			handler(Int(result))
			return
		}
	}

	func writeData(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyWriteDataWithIdentifier(identifier, data: data, handler: handler)
		}

		guard dispatch_semaphore_wait(writeSemaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 10)) == 0 else {
			handler(receivedData, Int(1))
			return
		}

		handler(receivedData, Int(kIOReturnSuccess))
	}

	private func actuallyWriteDataWithIdentifier(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		guard let currentIdentifier = currentIdentifier else {
			debugPrint("No open device; nowhere to write to.")
			handler(nil, Int(1))
			return
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			handler(nil, Int(1))
			return
		}

		let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
		let result = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, bytes, data.length)
		guard result == kIOReturnSuccess else {
			handler(nil, Int(result))
			return
		}
	}

	private func receivedReport() {
		assert(NSThread.isMainThread())

		receivedData = NSData(bytes: &inputReportBuffer, length: inputReportBuffer.count)
		dispatch_semaphore_signal(writeSemaphore)
	}

	func close(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyCloseWithIdentifier(identifier, handler: handler)
		}
	}

	private func actuallyCloseWithIdentifier(identifier: NSString, handler: Int -> ()) {
		assert(NSThread.isMainThread())

		guard let currentIdentifier = currentIdentifier else {
			debugPrint("No open device; nothing to close.")
			handler(Int(1))
			return
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			handler(Int(1))
			return
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			IOHIDDeviceClose(device, 0)
			device = nil
		}

		handler(Int(kIOReturnSuccess))
	}
}
