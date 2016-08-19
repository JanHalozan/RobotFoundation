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
			handler(Int(kIOReturnTimeout))
			return false
		}

		dispatch_sync(dispatch_get_main_queue()) {
			if let index = self.openSemaphores.indexOf({ return $0 === semaphore }) {
				self.openSemaphores.removeAtIndex(index)
			}
		}

		guard let openStatus = openStatus else {
			handler(Int(kIOReturnNotFound))
			return false
		}

		if openStatus != kIOReturnSuccess {
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
					return .AlreadyConnected
				}
				else {
					// Close now and open the new device.
					cancelDeferredClose()
					actuallyClose()
				}
			case .Opening(let device):
				if device.addressString == identifier {
					// Just don't close!
					cancelDeferredClose()
					activeClients += 1
					return .AlreadyOpening
				}
				else {
					// Close now and open the new device.
					cancelDeferredClose()
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
				return .AlreadyConnected
			}
			break
		case .Opening(let device):
			if device.addressString == identifier {
				return .AlreadyOpening
			}
			break
		}

		debugPrint("Tried to open a device while one was already open.")
		return .Error(Int(kIOReturnBusy))
	}

	private func openNewDevice(identifier: NSString) -> BluetoothAsyncOpenState {
		assert(NSThread.isMainThread())

		let device = IOBluetoothDevice(addressString: identifier as String)

		state = .Opening(device)

		let openResult = Int(device.openConnection(self))

		guard openResult == Int(kIOReturnSuccess) else {
			return .Error(openResult)
		}

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
			debugPrint("No open device; nothing to close.")
			return
		case .Open(let device):
			if device.addressString != identifier {
				debugPrint("Device mismatch.")
				return
			}
		case .Opening(let device):
			if device.addressString != identifier {
				debugPrint("Device mismatch.")
				return
			}
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			// Schedule a deferred close.
			awaitingDeferredClose = true

			BluetoothTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
			performSelector(#selector(actuallyClose), withObject: nil, afterDelay: 10)
		}
	}

	private func cancelDeferredClose() {
		assert(NSThread.isMainThread())
		BluetoothTransportService.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(actuallyClose), object: nil)
		awaitingDeferredClose = false
	}

	@objc private func actuallyClose() {
		assert(NSThread.isMainThread())

		cancelDeferredClose()

		// Channel might be `nil` if this is called in response to rfcommChannelClosed, but we still want to do the rest of the cleanup.
		channel?.closeChannel()
		channel = nil

		switch state {
		case .Open(let device):
			device.closeConnection()
		case .Opening(let device):
			device.closeConnection()
		case .Ready:
			assertionFailure()
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
			close(identifier)
			handler(errorCode)
			return
		case .Writing:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(semaphore, tenSecondTimeout()) == 0 else {
			close(identifier)
			handler(Int(kIOReturnTimeout))
			return
		}

		guard let writeStatus = writeStatus else {
			assertionFailure()
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
				print("Device mismatch.")
				return .Error(Int(kIOReturnInternalError))
			}
		case .Opening:
			fallthrough
		case .Ready:
			assertionFailure()
			return .Error(Int(kIOReturnNotOpen))
		}

		guard let channel = channel else {
			return .Error(Int(kIOReturnNoMedia))
		}

		var array = [UInt8](count: data.length, repeatedValue: 0)
		data.getBytes(&array, length: data.length)
		let status = channel.writeAsync(&array, length: UInt16(data.length), refcon: unsafeBitCast(semaphore, UnsafeMutablePointer<Void>.self))

		guard status == kIOReturnSuccess else {
			return .Error(Int(status))
		}

		return .Writing
	}

	@objc func rfcommChannelWriteComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutablePointer<Void>, status error: IOReturn) {
		assert(NSThread.isMainThread())
		assert(writeStatus == nil)

		writeStatus = error

		let semaphore = unsafeBitCast(refcon, dispatch_semaphore_t.self)
		dispatch_semaphore_signal(semaphore)
	}

	@objc func connectionComplete(device: IOBluetoothDevice, status: IOReturn) {
		assert(NSThread.isMainThread())

		guard status == kIOReturnSuccess else {
			finishedOpenWithError(status)
			return
		}

		let uuid = IOBluetoothSDPUUID(UUID16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		guard let record = device.getServiceRecordForUUID(uuid) else {
			finishedOpenWithError(kIOReturnNotFound)
			return
		}

		var channelID = BluetoothRFCOMMChannelID()
		let getChannelStatus = record.getRFCOMMChannelID(&channelID)

		guard getChannelStatus == kIOReturnSuccess else {
			finishedOpenWithError(getChannelStatus)
			return
		}

		var newChannel: IOBluetoothRFCOMMChannel?
		let openChannelStatus = device.openRFCOMMChannelAsync(&newChannel, withChannelID: channelID, delegate: self)

		guard openChannelStatus == kIOReturnSuccess else {
			finishedOpenWithError(openChannelStatus)
			return
		}

		guard let theNewChannel = newChannel else {
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

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}

		cancelDeferredClose()
		actuallyClose()

		// Writes will already fail gracefully, but we still tell clients about the close so they can, for example, cancel pending operations as well.
		delegate?.closedConnection()
	}

	func scheduleRead(identifier: NSString, handler: Int -> ()) {
		fatalError("Not supported")
	}
}
