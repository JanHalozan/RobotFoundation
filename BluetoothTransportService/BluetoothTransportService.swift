//
//  BluetoothTransportService.m
//  BluetoothTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOBluetooth

private func tenSecondTimeout() -> dispatch_time_t {
	return dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) * 10)
}

private enum BluetoothState {
	case Ready
	case Opening(IOBluetoothDevice)
	case Open(IOBluetoothDevice)
}

private enum BluetoothAsyncOpenState {
	case Opening
	case AlreadyConnected
	case AlreadyOpening
	case Error(Int)
}

private enum BluetoothAsyncWriteState {
	case Writing
	case Error(Int)
}

protocol BluetoothTransportServiceDelegate: class {
	func handleData(data: NSData)
	func closedConnection()
}

final class BluetoothTransportService : NSObject, XPCTransportServiceProtocol, IOBluetoothRFCOMMChannelDelegate {
	private var state: BluetoothState = .Ready
	private var channel: IOBluetoothRFCOMMChannel?
	private var awaitingDeferredClose = false

	private var connectingChannels = Set<IOBluetoothRFCOMMChannel>()

	private var activeClients = 0

	private var openSemaphores = [dispatch_semaphore_t]()
	private var openStatus: IOReturn?
	private var writeStatus: IOReturn?

	private weak var delegate: BluetoothTransportServiceDelegate?

	init(delegate: BluetoothTransportServiceDelegate) {
		self.delegate = delegate
	}

	private func open(identifier: NSString, handler: Int -> ()) -> Bool {
		NSLog("\(#function): beginning open request")

		let semaphore = dispatch_semaphore_create(0)

		var openState = BluetoothAsyncOpenState.Error(Int(kIOReturnInvalid))

		dispatch_sync(dispatch_get_main_queue()) {
			openState = self.actuallyOpenWithIdentifier(identifier)

			switch openState {
			case .AlreadyOpening:
				fallthrough
			case .Opening:
				self.openSemaphores.append(semaphore)
			default:
				break
			}
		}

		switch openState {
		case .AlreadyConnected:
			return true
		case .Error(let errorCode):
			handler(errorCode)
			return false
		case .AlreadyOpening:
			// continue on
			break
		case .Opening:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(semaphore, tenSecondTimeout()) == 0 else {
			NSLog("\(#function): opening the device timed out")
			handler(Int(kIOReturnTimeout))
			return false
		}

		dispatch_sync(dispatch_get_main_queue()) {
			if let index = self.openSemaphores.indexOf({ return $0 === semaphore }) {
				self.openSemaphores.removeAtIndex(index)
			}
		}

		guard let openStatus = openStatus else {
			assertionFailure("The open status should always be set right before signalling, but it was not.")
			NSLog("\(#function): could not retrieve an open status code")
			handler(Int(kIOReturnNotFound))
			return false
		}

		if openStatus != kIOReturnSuccess {
			NSLog("\(#function): opening the device failed")
			handler(Int(openStatus))
			return false
		}

		// We actually did it.
		dispatch_sync(dispatch_get_main_queue()) {
			switch self.state {
			case .Opening(let device):
				self.state = .Open(device)
				self.activeClients += 1
			case .Open:
				self.activeClients += 1
			default:
				assertionFailure()
			}
		}

		NSLog("\(#function): opened the device")

		return true
	}

	private func actuallyOpenWithIdentifier(identifier: NSString) -> BluetoothAsyncOpenState {
		if awaitingDeferredClose {
			switch state {
			case .Ready:
				assertionFailure()
				// Continue as usual.
			case .Open(let device):
				if device.addressString == identifier {
					// Just don't close!
					cancelDeferredClose()
					activeClients += 1
					NSLog("\(#function): cancelling a deferred close and increasing active clients to \(activeClients)")
					return .AlreadyConnected
				}
				else {
					// Close now and open the new device.
					NSLog("\(#function): cancelling a deferred close and opening a new device now")
					actuallyClose()
				}
			case .Opening(let device):
				if device.addressString == identifier {
					// Just don't close and wait until the open finishes before incrementing the active clients.
					cancelDeferredClose()
					NSLog("\(#function): cancelling a deferred close and waiting for existing opening")
					return .AlreadyOpening
				}
				else {
					// Close now and open the new device.
					NSLog("\(#function): cancelling a deferred close and opening a new device now")
					actuallyClose()
				}
			}
		}

		switch state {
		case .Ready:
			assert(activeClients == 0)
			return openNewDevice(identifier)
		case .Open(let device):
			if device.addressString == identifier {
				activeClients += 1
				NSLog("\(#function): reusing open connection and increasing active clients to \(activeClients)")
				return .AlreadyConnected
			}
			break
		case .Opening(let device):
			if device.addressString == identifier {
				// Wait until the open finishes before incrementing the active clients.
				NSLog("\(#function): cancelling a deferred close and waiting for existing opening")
				return .AlreadyOpening
			}
			break
		}

		NSLog("\(#function): tried to open a device while one was already open")
		return .Error(Int(kIOReturnBusy))
	}

	private func openNewDevice(identifier: NSString) -> BluetoothAsyncOpenState {
		assert(NSThread.isMainThread())

		let device = IOBluetoothDevice(addressString: identifier as String)
		let openResult = Int(device.openConnection(self))

		guard openResult == Int(kIOReturnSuccess) else {
			NSLog("\(#function): failed to open a baseband connection \(openResult)")
			return .Error(openResult)
		}

		state = .Opening(device)

		return .Opening
	}

	private func close(identifier: NSString) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyCloseWithIdentifier(identifier)
		}
	}

	private func actuallyCloseWithIdentifier(identifier: NSString) {
		assert(NSThread.isMainThread())

		switch state {
		case .Ready:
			return
		case .Open(let device):
			if device.addressString != identifier {
				return
			}
		case .Opening(let device):
			if device.addressString != identifier {
				return
			}
		}

		activeClients -= 1
		assert(activeClients >= 0)

		NSLog("\(#function): decreasing active clients to \(activeClients) after close")

		if activeClients == 0 {
			NSLog("\(#function): scheduling a deferred close")

			if awaitingDeferredClose {
				NSLog("\(#function): cancelling previous deferred close")
				BluetoothTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
			}

			// Schedule a deferred close.
			awaitingDeferredClose = true
			performSelector(#selector(actuallyClose), withObject: nil, afterDelay: 10)
		}
	}

	private func cancelDeferredClose() {
		assert(NSThread.isMainThread())
		NSLog("\(#function): cancelling deferred close")
		BluetoothTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
		awaitingDeferredClose = false
	}

	@objc private func actuallyClose() {
		assert(NSThread.isMainThread())

		NSLog("\(#function): actually closing the device")

		cancelDeferredClose()

		func cleanUpDevice(device: IOBluetoothDevice) {
			channel?.closeChannel()
			channel = nil

			device.closeConnection()
		}

		switch state {
		case .Ready:
			// Just ignore this. Calling device.closeConnection will cause the RFCOMM did close delegate method to get invoked, which in turn invokes actuallyClose again, but we're already closed by then.
			assert(activeClients == 0)
			return
		case .Open(let device):
			cleanUpDevice(device)
		case .Opening(let device):
			cleanUpDevice(device)
		}

		state = .Ready
		activeClients = 0
	}

	func writeData(data: NSData, identifier: NSString, handler: Int -> ()) {
		if !open(identifier, handler: handler) {
			return
		}

		var writeState = BluetoothAsyncWriteState.Error(Int(kIOReturnInvalid))

		let semaphore = dispatch_semaphore_create(0)

		dispatch_sync(dispatch_get_main_queue()) {
			writeState = self.actuallyWriteData(data, identifier: identifier, semaphore: semaphore)
		}

		switch writeState {
		case .Error(let errorCode):
			NSLog("\(#function): actual write failed: \(errorCode)")
			close(identifier)
			handler(errorCode)
			return
		case .Writing:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(semaphore, tenSecondTimeout()) == 0 else {
			NSLog("\(#function): timed out while waiting for write")
			close(identifier)
			handler(Int(kIOReturnTimeout))
			return
		}

		guard let writeStatus = writeStatus else {
			assertionFailure()
			NSLog("\(#function): could not obtain a write status code")
			close(identifier)
			handler(Int(kIOReturnInternalError))
			return
		}

		dispatch_sync(dispatch_get_main_queue()) {
			self.writeStatus = nil
		}

		close(identifier)
		handler(Int(writeStatus))
	}

	private func actuallyWriteData(data: NSData, identifier: NSString, semaphore: dispatch_semaphore_t) -> BluetoothAsyncWriteState {
		assert(NSThread.isMainThread())

		switch state {
		case .Open(let device):
			guard device.addressString == identifier else {
				return .Error(Int(kIOReturnInternalError))
			}
		case .Opening:
			fallthrough
		case .Ready:
			assertionFailure()
			return .Error(Int(kIOReturnNotOpen))
		}

		guard let channel = channel else {
			NSLog("\(#function): there is no channel to write")
			return .Error(Int(kIOReturnNoMedia))
		}

		var array = [UInt8](count: data.length, repeatedValue: 0)
		data.getBytes(&array, length: data.length)
		let status = channel.writeAsync(&array, length: UInt16(data.length), refcon: unsafeBitCast(semaphore, UnsafeMutablePointer<Void>.self))

		guard status == kIOReturnSuccess else {
			NSLog("\(#function): beginning the write failed: \(status)")
			return .Error(Int(status))
		}

		return .Writing
	}

	@objc func rfcommChannelWriteComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutablePointer<Void>, status error: IOReturn) {
		assert(NSThread.isMainThread())
		assert(writeStatus == nil)

		if error != kIOReturnSuccess {
			NSLog("\(#function): writing failed: \(error)")
		}

		writeStatus = error

		let semaphore = unsafeBitCast(refcon, dispatch_semaphore_t.self)
		dispatch_semaphore_signal(semaphore)
	}

	@objc func connectionComplete(device: IOBluetoothDevice, status: IOReturn) {
		assert(NSThread.isMainThread())

		guard status == kIOReturnSuccess else {
			NSLog("\(#function): opening connection failed: \(status)")
			finishedOpenWithError(status)
			return
		}

		let uuid = IOBluetoothSDPUUID(UUID16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		guard let record = device.getServiceRecordForUUID(uuid) else {
			NSLog("\(#function): obtaining service record failed")
			finishedOpenWithError(kIOReturnNotFound)
			return
		}

		var channelID = BluetoothRFCOMMChannelID()
		let getChannelStatus = record.getRFCOMMChannelID(&channelID)

		guard getChannelStatus == kIOReturnSuccess else {
			NSLog("\(#function): obtaining RFCOMM channnel ID failed")
			finishedOpenWithError(getChannelStatus)
			return
		}

		var newChannel: IOBluetoothRFCOMMChannel?
		let openChannelStatus = device.openRFCOMMChannelAsync(&newChannel, withChannelID: channelID, delegate: self)

		guard openChannelStatus == kIOReturnSuccess else {
			NSLog("\(#function): beginning to open RFCOMM channel failed \(openChannelStatus)")
			finishedOpenWithError(openChannelStatus)
			return
		}

		guard let theNewChannel = newChannel else {
			NSLog("\(#function): the RFCOMM channel is nil")
			finishedOpenWithError(kIOReturnNotFound)
			return
		}

		connectingChannels.insert(theNewChannel)
	}

	private func finishedOpenWithError(error: IOReturn) {
		assert(NSThread.isMainThread())

		openStatus = error

		for semaphore in openSemaphores {
			dispatch_semaphore_signal(semaphore)
		}
	}

	@objc func rfcommChannelOpenComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
		assert(NSThread.isMainThread())

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}

		assert(connectingChannels.isEmpty)

		if error == kIOReturnSuccess {
			self.channel = rfcommChannel
		} else {
			NSLog("\(#function): opening RFCOMM channel failed: \(error)")
		}

		finishedOpenWithError(error)
	}

	@objc func rfcommChannelData(rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutablePointer<Void>, length dataLength: Int) {
		assert(NSThread.isMainThread())

		let receivedData = NSData(bytes: dataPointer, length: dataLength)
		delegate?.handleData(receivedData)
	}

	@objc func rfcommChannelClosed(rfcommChannel: IOBluetoothRFCOMMChannel!) {
		assert(NSThread.isMainThread())

		NSLog("\(#function): RFCOMM channel was closed")

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}

		actuallyClose()

		// Writes will already fail gracefully, but we still tell clients about the close so they can, for example, cancel pending operations as well.
		delegate?.closedConnection()
	}

	func scheduleRead(identifier: NSString, handler: Int -> ()) {
		fatalError("Not supported")
	}
}
