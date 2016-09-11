//
//  BluetoothTransportService.m
//  BluetoothTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOBluetooth

private func tenSecondTimeout() -> DispatchTime {
	return DispatchTime.now() + 10
}

private enum BluetoothState {
	case ready
	case opening(IOBluetoothDevice)
	case open(IOBluetoothDevice)
}

private enum BluetoothAsyncOpenState {
	case opening
	case alreadyConnected
	case alreadyOpening
	case error(Int)
}

private enum BluetoothAsyncWriteState {
	case writing
	case error(Int)
}

final class BluetoothTransportService : NSObject, TransportServiceProtocol, IOBluetoothRFCOMMChannelDelegate {
	private var state: BluetoothState = .ready
	private var channel: IOBluetoothRFCOMMChannel?
	private var awaitingDeferredClose = false

	private var connectingChannels = Set<IOBluetoothRFCOMMChannel>()

	private var activeClients = 0

	private var openSemaphores = [DispatchSemaphore]()
	private var openStatus: IOReturn?
	private var writeStatus: IOReturn?

	private weak var delegate: TransportClientProtocol?

	init(delegate: TransportClientProtocol) {
		self.delegate = delegate
	}

	private func open(_ identifier: NSString, handler: (Int) -> ()) -> Bool {
		NSLog("\(#function): beginning open request")

		let semaphore = DispatchSemaphore(value: 0)

		var openState = BluetoothAsyncOpenState.error(Int(kIOReturnInvalid))

		DispatchQueue.main.sync {
			openState = self.actuallyOpenWithIdentifier(identifier)

			switch openState {
			case .alreadyOpening:
				fallthrough
			case .opening:
				self.openSemaphores.append(semaphore)
			default:
				break
			}
		}

		switch openState {
		case .alreadyConnected:
			return true
		case .error(let errorCode):
			handler(errorCode)
			return false
		case .alreadyOpening:
			// continue on
			break
		case .opening:
			// continue on
			break
		}

		guard semaphore.wait(timeout: tenSecondTimeout()) == DispatchTimeoutResult.success else {
			NSLog("\(#function): opening the device timed out")

			// Cancel everything if timed out.
			DispatchQueue.main.sync {
				self.actuallyClose()
			}

			handler(Int(kIOReturnTimeout))
			return false
		}

		DispatchQueue.main.sync {
			if let index = self.openSemaphores.index(where: { return $0 === semaphore }) {
				self.openSemaphores.remove(at: index)
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
		DispatchQueue.main.sync {
			switch self.state {
			case .opening(let device):
				self.state = .open(device)
				self.activeClients += 1
			case .open:
				self.activeClients += 1
			default:
				assertionFailure()
			}
		}

		NSLog("\(#function): opened the device")

		return true
	}

	private func actuallyOpenWithIdentifier(_ identifier: NSString) -> BluetoothAsyncOpenState {
		if awaitingDeferredClose {
			switch state {
			case .ready:
				assertionFailure()
				// Continue as usual.
			case .open(let device):
				if device.addressString == identifier as String {
					// Just don't close!
					cancelDeferredClose()
					activeClients += 1
					NSLog("\(#function): cancelling a deferred close and increasing active clients to \(activeClients)")
					return .alreadyConnected
				}
				else {
					// Close now and open the new device.
					NSLog("\(#function): cancelling a deferred close and opening a new device now")
					actuallyClose()
				}
			case .opening(let device):
				if device.addressString == identifier as String {
					// Just don't close and wait until the open finishes before incrementing the active clients.
					cancelDeferredClose()
					NSLog("\(#function): cancelling a deferred close and waiting for existing opening")
					return .alreadyOpening
				}
				else {
					// Close now and open the new device.
					NSLog("\(#function): cancelling a deferred close and opening a new device now")
					actuallyClose()
				}
			}
		}

		switch state {
		case .ready:
			assert(activeClients == 0)
			return openNewDevice(identifier)
		case .open(let device):
			if device.addressString == identifier as String {
				activeClients += 1
				NSLog("\(#function): reusing open connection and increasing active clients to \(activeClients)")
				return .alreadyConnected
			}
			break
		case .opening(let device):
			if device.addressString == identifier as String {
				// Wait until the open finishes before incrementing the active clients.
				NSLog("\(#function): cancelling a deferred close and waiting for existing opening")
				return .alreadyOpening
			}
			break
		}

		NSLog("\(#function): tried to open a device while one was already open")
		return .error(Int(kIOReturnBusy))
	}

	private func openNewDevice(_ identifier: NSString) -> BluetoothAsyncOpenState {
		assert(Thread.isMainThread)

		guard let device = IOBluetoothDevice(addressString: identifier as String) else {
			return .error(Int(kIOReturnNoDevice))
		}

		let openResult = Int(device.openConnection(self))

		guard openResult == Int(kIOReturnSuccess) else {
			NSLog("\(#function): failed to open a baseband connection \(openResult)")
			return .error(openResult)
		}

		state = .opening(device)

		return .opening
	}

	private func close(_ identifier: NSString) {
		DispatchQueue.main.sync {
			self.actuallyCloseWithIdentifier(identifier)
		}
	}

	private func actuallyCloseWithIdentifier(_ identifier: NSString) {
		assert(Thread.isMainThread)

		switch state {
		case .ready:
			return
		case .open(let device):
			if device.addressString != identifier as String {
				return
			}
		case .opening(let device):
			if device.addressString != identifier as String {
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
				BluetoothTransportService.cancelPreviousPerformRequests(withTarget: self, selector: #selector(actuallyClose), object: nil)
			}

			// Schedule a deferred close.
			awaitingDeferredClose = true
			perform(#selector(actuallyClose), with: nil, afterDelay: 10)
		}
	}

	private func cancelDeferredClose() {
		assert(Thread.isMainThread)
		NSLog("\(#function): cancelling deferred close")
		BluetoothTransportService.cancelPreviousPerformRequests(withTarget: self, selector: #selector(actuallyClose), object: nil)
		awaitingDeferredClose = false
	}

	@objc private func actuallyClose() {
		assert(Thread.isMainThread)

		NSLog("\(#function): actually closing the device")

		cancelDeferredClose()

		func cleanUpDevice(_ device: IOBluetoothDevice) {
			channel?.close()
			channel = nil

			device.closeConnection()
		}

		switch state {
		case .ready:
			// Just ignore this. Calling device.closeConnection will cause the RFCOMM did close delegate method to get invoked, which in turn invokes actuallyClose again, but we're already closed by then.
			assert(activeClients == 0)
			return
		case .open(let device):
			cleanUpDevice(device)
		case .opening(let device):
			cleanUpDevice(device)
		}

		state = .ready
		activeClients = 0
	}

	func writeData(_ data: NSData, identifier: NSString, handler: @escaping (Int) -> ()) {
		if !open(identifier, handler: handler) {
			return
		}

		var writeState = BluetoothAsyncWriteState.error(Int(kIOReturnInvalid))

		let semaphore = DispatchSemaphore(value: 0)

		DispatchQueue.main.sync {
			writeState = self.actuallyWriteData(data as Data, identifier: identifier, semaphore: semaphore)
		}

		switch writeState {
		case .error(let errorCode):
			NSLog("\(#function): actual write failed: \(errorCode)")
			close(identifier)
			handler(errorCode)
			return
		case .writing:
			// continue on
			break
		}

		guard semaphore.wait(timeout: tenSecondTimeout()) == DispatchTimeoutResult.success else {
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

		DispatchQueue.main.sync {
			self.writeStatus = nil
		}

		close(identifier)
		handler(Int(writeStatus))
	}

	private func actuallyWriteData(_ data: Data, identifier: NSString, semaphore: DispatchSemaphore) -> BluetoothAsyncWriteState {
		assert(Thread.isMainThread)

		switch state {
		case .open(let device):
			guard device.addressString == identifier as String else {
				return .error(Int(kIOReturnInternalError))
			}
		case .opening:
			fallthrough
		case .ready:
			assertionFailure()
			return .error(Int(kIOReturnNotOpen))
		}

		guard let channel = channel else {
			NSLog("\(#function): there is no channel to write")
			return .error(Int(kIOReturnNoMedia))
		}

		var array = [UInt8](repeating: 0, count: data.count)
		data.copyBytes(to: &array, count: data.count)
		let status = channel.writeAsync(&array, length: UInt16(data.count), refcon: unsafeBitCast(semaphore, to: UnsafeMutableRawPointer.self))

		guard status == kIOReturnSuccess else {
			NSLog("\(#function): beginning the write failed: \(status)")
			return .error(Int(status))
		}

		return .writing
	}

	@objc func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {
		assert(Thread.isMainThread)
		assert(writeStatus == nil)

		if error != kIOReturnSuccess {
			NSLog("\(#function): writing failed: \(error)")
		}

		writeStatus = error

		let semaphore = unsafeBitCast(refcon, to: DispatchSemaphore.self)
		semaphore.signal()
	}

	@objc func connectionComplete(_ device: IOBluetoothDevice, status: IOReturn) {
		assert(Thread.isMainThread)

		guard status == kIOReturnSuccess else {
			NSLog("\(#function): opening connection failed: \(status)")
			finishedOpenWithError(status)
			return
		}

		let uuid = IOBluetoothSDPUUID(uuid16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		guard let record = device.getServiceRecord(for: uuid) else {
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

	private func finishedOpenWithError(_ error: IOReturn) {
		assert(Thread.isMainThread)

		openStatus = error

		if error != kIOReturnSuccess {
			actuallyClose()
		}

		for semaphore in openSemaphores {
			semaphore.signal()
		}
	}

	@objc func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
		assert(Thread.isMainThread)

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

	@objc func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
		assert(Thread.isMainThread)

		let receivedData = Data(bytes: UnsafeRawPointer(dataPointer), count: dataLength)
		delegate?.handleTransportData(receivedData as NSData)
	}

	@objc func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
		assert(Thread.isMainThread)

		NSLog("\(#function): RFCOMM channel was closed")

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}

		actuallyClose()

		// Writes will already fail gracefully, but we still tell clients about the close so they can, for example, cancel pending operations as well.
		delegate?.closedTransportConnection()
	}

	func scheduleRead(_ identifier: NSString, handler: @escaping (Int) -> ()) {
		fatalError("Not supported")
	}
}
