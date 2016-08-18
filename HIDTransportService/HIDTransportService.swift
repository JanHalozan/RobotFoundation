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
	func closedConnection()
}

final class HIDTransportService : NSObject, XPCTransportServiceProtocol {
	private var device: IOHIDDevice?
	private var activeClients = 0
	private var awaitingDeferredClose = false
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

		return IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey)?.takeUnretainedValue() as? String
	}

	private func open(identifier: NSString, handler: Int -> ()) -> Bool {
		var result = false
		dispatch_sync(dispatch_get_main_queue()) {
			result = self.actuallyOpenWithIdentifier(identifier, handler: handler)
		}
		return result
	}

	private func actuallyOpenWithIdentifier(identifier: NSString, handler: Int -> ()) -> Bool {
		assert(NSThread.isMainThread())

		if awaitingDeferredClose {
			if currentIdentifier == nil {
				// Just go on and open.
			} else if currentIdentifier! == identifier {
				// Bring back the connection we have.
				cancelDeferredClose()
				activeClients += 1
				return true
			} else {
				// Cancel immediately and re-open.
				cancelDeferredClose()
				actuallyClose()
			}
		}

		if currentIdentifier == nil {
			assert(activeClients == 0)

			let openResult = openNewDevice(identifier)
			guard openResult == Int(kIOReturnSuccess) else {
				handler(openResult)
				return false
			}

			activeClients += 1
			return true
		} else if currentIdentifier! == identifier {
			activeClients += 1
			return true
		} else {
			print("Tried to open a device while one was already open.")
			handler(Int(kIOReturnStillOpen))
			return false
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

		IOHIDDeviceRegisterRemovalCallback(hidDevice, { context, result, refcon in

			let selfPointer = unsafeBitCast(context, HIDTransportService.self)
			selfPointer.closedConnection()

		}, UnsafeMutablePointer(unsafeAddressOf(self)))

		device = hidDevice

		return Int(kIOReturnSuccess)
	}

	private func closedConnection() {
		assert(NSThread.isMainThread())

		cancelDeferredClose()
		actuallyClose()

		delegate?.closedConnection()
	}

	func writeData(data: NSData, identifier: NSString, handler: Int -> ()) {
		if !open(identifier, handler: handler) {
			return
		}

		var result: IOReturn?

		dispatch_sync(dispatch_get_main_queue()) {
			result = self.actuallyWriteData(data, identifier: identifier)
		}

		guard let theResult = result else {
			assertionFailure()
			close(identifier)
			handler(Int(kIOReturnInternalError))
			return
		}

		close(identifier)
		handler(Int(theResult))
	}

	private func actuallyWriteData(data: NSData, identifier: NSString) -> IOReturn {
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

	private func close(identifier: NSString) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyCloseWithIdentifier(identifier)
		}
	}

	private func actuallyCloseWithIdentifier(identifier: NSString) {
		assert(NSThread.isMainThread())

		guard let currentIdentifier = currentIdentifier else {
			print("No open device; nothing to close.")
			return
		}

		guard currentIdentifier == identifier else {
			print("Device mismatch.")
			return
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			// Schedule a deferred close.
			awaitingDeferredClose = true

			HIDTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
			performSelector(#selector(actuallyClose), withObject: nil, afterDelay: 10)
		}
	}

	private func cancelDeferredClose() {
		assert(NSThread.isMainThread())
		HIDTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
		awaitingDeferredClose = false
	}

	@objc private func actuallyClose() {
		if let existingDevice = device {
			IOHIDDeviceClose(existingDevice, 0)
		} else {
			assertionFailure()
		}

		device = nil
		awaitingDeferredClose = false
		activeClients = 0
	}

	func scheduleRead(identifier: NSString, handler: Int -> ()) {
		fatalError("Not supported")
	}
}
