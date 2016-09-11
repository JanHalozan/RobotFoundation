//
//  HIDTransportService.h
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOKit.hid

final class HIDTransportService : NSObject, TransportServiceProtocol {
	private var device: IOHIDDevice?
	private var activeClients = 0
	private var awaitingDeferredClose = false
	private var inputReportBuffer = [UInt8](repeating: 0, count: 1024)

	private weak var delegate: TransportClientProtocol?

	init(delegate: TransportClientProtocol) {
		self.delegate = delegate
	}

	private var currentIdentifier: String? {
		assert(Thread.isMainThread)

		guard let device = device else {
			return nil
		}

		return IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String
	}

	private func open(_ identifier: NSString, handler: (Int) -> ()) -> Bool {
		var result = false
		DispatchQueue.main.sync {
			result = self.actuallyOpenWithIdentifier(identifier, handler: handler)
		}
		return result
	}

	private func actuallyOpenWithIdentifier(_ identifier: NSString, handler: (Int) -> ()) -> Bool {
		assert(Thread.isMainThread)

		if awaitingDeferredClose {
			if currentIdentifier == nil {
				// Just go on and open.
			} else if currentIdentifier! == identifier as String {
				// Bring back the connection we have.
				cancelDeferredClose()
				activeClients += 1
				return true
			} else {
				// Cancel immediately and re-open.
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
		} else if currentIdentifier! == identifier as String {
			activeClients += 1
			return true
		} else {
			print("Tried to open a device while one was already open.")
			handler(Int(kIOReturnStillOpen))
			return false
		}
	}

	private func openNewDevice(_ identifier: NSString) -> Int {
		let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary
		matching[kIOHIDSerialNumberKey] = identifier

		let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching as CFDictionary)

		guard let hidDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service) else {
			return 1
		}

		IOHIDDeviceRegisterInputReportCallback(hidDevice, &inputReportBuffer, inputReportBuffer.count, { context, result, interface, reportType, index, bytes, length in

			let selfPointer = unsafeBitCast(context, to: HIDTransportService.self)
			selfPointer.receivedReport()
		}, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
		IOHIDDeviceScheduleWithRunLoop(hidDevice, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

		let result = IOHIDDeviceOpen(hidDevice, 0)
		guard result == kIOReturnSuccess else {
			return Int(result)
		}

		IOHIDDeviceRegisterRemovalCallback(hidDevice, { context, result, refcon in

			let selfPointer = unsafeBitCast(context, to: HIDTransportService.self)
			selfPointer.closedConnection()

		}, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

		device = hidDevice

		return Int(kIOReturnSuccess)
	}

	private func closedConnection() {
		assert(Thread.isMainThread)

		actuallyClose()

		delegate?.closedTransportConnection()
	}

	func writeData(_ data: NSData, identifier: NSString, handler: @escaping (Int) -> ()) {
		if !open(identifier, handler: handler) {
			return
		}

		var result: IOReturn?

		DispatchQueue.main.sync {
			result = self.actuallyWriteData(data as Data, identifier: identifier)
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

	private func actuallyWriteData(_ data: Data, identifier: NSString) -> IOReturn {
		guard let currentIdentifier = currentIdentifier else {
			debugPrint("No open device; nowhere to write to.")
			return kIOReturnNotOpen
		}

		guard currentIdentifier == identifier as String else {
			debugPrint("Device mismatch.")
			return kIOReturnInternalError
		}

		if let existingDevice = device {
			return data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
				return IOHIDDeviceSetReport(existingDevice, kIOHIDReportTypeOutput, 0, bytes, data.count)
			}
		} else {
			assertionFailure()
			return kIOReturnNoDevice
		}
	}

	private func receivedReport() {
		assert(Thread.isMainThread)

		let receivedData = Data(bytes: &inputReportBuffer, count: inputReportBuffer.count)
		delegate?.handleTransportData(receivedData as NSData)
	}

	private func close(_ identifier: NSString) {
		DispatchQueue.main.sync {
			self.actuallyCloseWithIdentifier(identifier)
		}
	}

	private func actuallyCloseWithIdentifier(_ identifier: NSString) {
		assert(Thread.isMainThread)

		guard let currentIdentifier = currentIdentifier else {
			print("No open device; nothing to close.")
			return
		}

		guard currentIdentifier == identifier as String else {
			print("Device mismatch.")
			return
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			if awaitingDeferredClose {
				HIDTransportService.cancelPreviousPerformRequests(withTarget: self, selector: #selector(actuallyClose), object: nil)
			}

			// Schedule a deferred close.
			awaitingDeferredClose = true
			perform(#selector(actuallyClose), with: nil, afterDelay: 10)
		}
	}

	private func cancelDeferredClose() {
		assert(Thread.isMainThread)
		HIDTransportService.cancelPreviousPerformRequests(withTarget: self, selector: #selector(actuallyClose), object: nil)
		awaitingDeferredClose = false
	}

	@objc private func actuallyClose() {
		cancelDeferredClose()

		if let existingDevice = device {
			IOHIDDeviceClose(existingDevice, 0)
		} else {
			assertionFailure()
		}

		device = nil
		activeClients = 0
	}

	func scheduleRead(_ identifier: NSString, handler: @escaping (Int) -> ()) {
		fatalError("Not supported")
	}
}
