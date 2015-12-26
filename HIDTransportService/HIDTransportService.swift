//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOKit.hid

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
final class HIDTransportService : NSObject, XPCTransportServiceProtocol {
	private var device: IOHIDDeviceRef?
	private var inputReportBuffer = [UInt8](count: 1024, repeatedValue: 0)

	private let connection: NSXPCConnection

	init(connection: NSXPCConnection) {
		self.connection = connection
		super.init()
	}

	// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
	func open(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
			matching[kIOHIDSerialNumberKey] = identifier

			let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching as CFDictionaryRef)

			self.device = IOHIDDeviceCreate(kCFAllocatorDefault, service)!.takeRetainedValue()

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

			handler(Int(kIOReturnSuccess))
		}
	}

	func writeData(data: NSData, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)
			let result = IOHIDDeviceSetReport(self.device, kIOHIDReportTypeOutput, 0, bytes, data.length)
			guard result == kIOReturnSuccess else {
				handler(Int(result))
				return
			}

			handler(Int(kIOReturnSuccess))
		}
	}

	private func receivedReport() {
		let data = NSData(bytes: &inputReportBuffer, length: inputReportBuffer.count)
		let proxy = connection.remoteObjectProxy as? XPCTransportServiceClientProtocol
		proxy?.didReceiveData(data)
	}

	func close(handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			IOHIDDeviceClose(self.device, 0)
			handler(Int(kIOReturnSuccess))
		}
	}
}
