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

			let openResult = openNewDevice(identifier)
			guard openResult == Int(kIOReturnSuccess) else {
				handler(openResult)
				return
			}

			activeClients += 1
			handler(Int(kIOReturnSuccess))
		} else if currentIdentifier! == identifier {
			activeClients += 1
			handler(Int(kIOReturnSuccess))
		} else {
			debugPrint("Tried to open a device while one was already open.")
			handler(Int(kIOReturnStillOpen))
		}
	}

	private func openNewDevice(identifier: NSString) -> Int {
		let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
		matching[kIOHIDSerialNumberKey] = identifier

		let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching as CFDictionaryRef)

		guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service)?.takeRetainedValue() else {
			return 1
		}

		IOHIDDeviceRegisterInputReportCallback(hidDevice, &inputReportBuffer, inputReportBuffer.count, { context, result, interface, reportType, index, bytes, length in

			let selfPointer = unsafeBitCast(context, HIDTransportService.self)
			selfPointer.receivedReport()

		}, UnsafeMutablePointer(unsafeAddressOf(self)))
		IOHIDDeviceScheduleWithRunLoop(hidDevice, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

		let result = IOHIDDeviceOpen(hidDevice, 0)
		guard result == kIOReturnSuccess else {
			return Int(result)
		}

		device = hidDevice

		return Int(kIOReturnSuccess)
	}

	func writeData(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyWriteDataWithIdentifier(identifier, data: data, handler: handler)
		}

		guard dispatch_semaphore_wait(writeSemaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 10)) == 0 else {
			handler(receivedData, Int(kIOReturnTimeout))
			return
		}

		handler(receivedData, Int(kIOReturnSuccess))
	}

	private func actuallyWriteDataWithIdentifier(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		guard let currentIdentifier = currentIdentifier else {
			debugPrint("No open device; nowhere to write to.")
			handler(nil, Int(kIOReturnNotOpen))
			return
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			handler(nil, Int(kIOReturnInternalError))
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
			handler(Int(kIOReturnNotOpen))
			return
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			handler(Int(kIOReturnInternalError))
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
