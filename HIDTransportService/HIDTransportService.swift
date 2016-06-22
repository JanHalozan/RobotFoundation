//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOKit.hid

protocol HIDTransportServiceDelegate: class {
	func handleData(data: NSData)
}

final class HIDTransportService : NSObject, XPCTransportServiceProtocol {
	private var device: IOHIDDevice?
	private var activeClients = 0
	private var inputReportBuffer = [UInt8](count: 1024, repeatedValue: 0)

	private weak var delegate: HIDTransportServiceDelegate?

	init(delegate: HIDTransportServiceDelegate) {
		self.delegate = delegate
	}

	private var currentIdentifier: String? {
		assert(NSThread.isMainThread())

		guard let device = device else {
			return nil
		}

		return IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey) as? String
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

		guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service) else {
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

	func writeData(identifier: NSString, data: NSData, handler: Int -> ()) {
		var result: IOReturn?

		dispatch_sync(dispatch_get_main_queue()) {
			result = self.actuallyWriteDataWithIdentifier(identifier, data: data)
		}

		guard let theResult = result else {
			assertionFailure()
			handler(Int(kIOReturnInternalError))
			return
		}

		handler(Int(theResult))
	}

	private func actuallyWriteDataWithIdentifier(identifier: NSString, data: NSData) -> IOReturn {
		guard let currentIdentifier = currentIdentifier else {
			debugPrint("No open device; nowhere to write to.")
			return kIOReturnNotOpen
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			return kIOReturnInternalError
		}

		let bytes = unsafeBitCast(data.bytes, UnsafePointer<UInt8>.self)

		if let existingDevice = device {
			return IOHIDDeviceSetReport(existingDevice, kIOHIDReportTypeOutput, 0, bytes, data.length)
		} else {
			assertionFailure()
			return kIOReturnNoDevice
		}
	}

	private func receivedReport() {
		assert(NSThread.isMainThread())

		let receivedData = NSData(bytes: &inputReportBuffer, length: inputReportBuffer.count)
		delegate?.handleData(receivedData)
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
			if let existingDevice = device {
				IOHIDDeviceClose(existingDevice, 0)
			} else {
				assertionFailure()
			}

			device = nil
		}

		handler(Int(kIOReturnSuccess))
	}
}
