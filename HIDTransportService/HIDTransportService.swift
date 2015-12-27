//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOKit.hid

final class HIDTransportService : NSObject, XPCTransportServiceProtocol {
	private var device: IOHIDDeviceRef?
	private var inputReportBuffer = [UInt8](count: 1024, repeatedValue: 0)

	private var writeSemaphore = dispatch_semaphore_create(0)
	private var receivedData: NSData?

	private let connection: NSXPCConnection

	init(connection: NSXPCConnection) {
		self.connection = connection
		super.init()
	}

	func open(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
			matching[kIOHIDSerialNumberKey] = identifier

			let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching as CFDictionaryRef)

			guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service)?.takeRetainedValue() else {
				handler(1)
				return
			}

			self.device = hidDevice

			IOHIDDeviceRegisterInputReportCallback(self.device, &self.inputReportBuffer, self.inputReportBuffer.count, { context, result, interface, reportType, index, bytes, length in

				let selfPointer = unsafeBitCast(context, HIDTransportService.self)
				selfPointer.receivedReport()

			}, UnsafeMutablePointer(unsafeAddressOf(self)))
			IOHIDDeviceScheduleWithRunLoop(self.device, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)

			let result = IOHIDDeviceOpen(self.device, 0)
			guard result == kIOReturnSuccess else {
				handler(Int(result))
				return
			}
		}

		handler(Int(kIOReturnSuccess))
	}

	func writeData(data: NSData, handler: (NSData?, Int) -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
			let result = IOHIDDeviceSetReport(self.device, kIOHIDReportTypeOutput, 0, bytes, data.length)
			guard result == kIOReturnSuccess else {
				handler(nil, Int(result))
				return
			}
		}

		guard dispatch_semaphore_wait(writeSemaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 10)) == 0 else {
			handler(receivedData, Int(1))
			return
		}

		handler(receivedData, Int(kIOReturnSuccess))
	}

	private func receivedReport() {
		assert(NSThread.isMainThread())

		receivedData = NSData(bytes: &inputReportBuffer, length: inputReportBuffer.count)
		dispatch_semaphore_signal(writeSemaphore)
	}

	func close(handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			IOHIDDeviceClose(self.device, 0)
		}

		handler(Int(kIOReturnSuccess))
	}
}
