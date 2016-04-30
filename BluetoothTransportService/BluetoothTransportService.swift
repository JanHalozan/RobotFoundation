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
}

final class BluetoothTransportService : NSObject, XPCTransportServiceProtocol, IOBluetoothRFCOMMChannelDelegate {
	private var state: BluetoothState = .Ready
	private var channel: IOBluetoothRFCOMMChannel?

	private var connectingChannels = Set<IOBluetoothRFCOMMChannel>()

	private var activeClients = 0

	private var openSemaphores = [dispatch_semaphore_t]()
	private var openStatus: IOReturn?
	private var writeStatus: IOReturn?

	private weak var delegate: BluetoothTransportServiceDelegate?

	init(delegate: BluetoothTransportServiceDelegate) {
		self.delegate = delegate
	}

	func open(identifier: NSString, handler: Int -> ()) {
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
			handler(Int(kIOReturnSuccess))
			return
		case .Error(let errorCode):
			handler(errorCode)
			return
		case .AlreadyOpening:
			// continue on
			break
		case .Opening:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(semaphore, tenSecondTimeout()) == 0 else {
			handler(Int(kIOReturnTimeout))
			return
		}

		dispatch_sync(dispatch_get_main_queue()) {
			if let index = self.openSemaphores.indexOf({ return $0 === semaphore }) {
				self.openSemaphores.removeAtIndex(index)
			}
		}

		guard let openStatus = openStatus else {
			handler(Int(kIOReturnNotFound))
			return
		}

		if openStatus == kIOReturnSuccess {
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
		}

		handler(Int(openStatus))
	}

	private func actuallyOpenWithIdentifier(identifier: NSString) -> BluetoothAsyncOpenState {
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

	func close(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.actuallyCloseWithIdentifier(identifier, handler: handler)
		}
	}

	private func actuallyCloseWithIdentifier(identifier: NSString, handler: Int -> ()) {
		assert(NSThread.isMainThread())

		switch state {
		case .Ready:
			debugPrint("No open device; nothing to close.")
			handler(Int(kIOReturnNotOpen))
			return
		case .Open(let device):
			if device.addressString != identifier {
				debugPrint("Device mismatch.")
				handler(Int(kIOReturnInternalError))
				return
			}
			break
		case .Opening(let device):
			if device.addressString != identifier {
				debugPrint("Device mismatch.")
				handler(Int(kIOReturnInternalError))
				return
			}
			break
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			assert(channel != nil)
			channel?.closeChannel()
			channel = nil

			switch state {
			case .Open(let device):
				device.closeConnection()
				break
			case .Opening(let device):
				device.closeConnection()
				break
			case .Ready:
				assertionFailure()
				break
			}

			state = .Ready
		}

		handler(Int(kIOReturnSuccess))
	}

	func writeData(identifier: NSString, data: NSData, handler: Int -> ()) {
		var writeState = BluetoothAsyncWriteState.Error(Int(kIOReturnInvalid))

		let semaphore = dispatch_semaphore_create(0)

		dispatch_sync(dispatch_get_main_queue()) {
			writeState = self.actuallyWriteData(identifier, data: data, semaphore: semaphore)
		}

		switch writeState {
		case .Error(let errorCode):
			handler(errorCode)
			return
		case .Writing:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(semaphore, tenSecondTimeout()) == 0 else {
			handler(Int(kIOReturnTimeout))
			return
		}

		guard let writeStatus = writeStatus else {
			assertionFailure()
			handler(Int(kIOReturnInternalError))
			return
		}

		dispatch_sync(dispatch_get_main_queue()) {
			self.writeStatus = nil
		}

		handler(Int(writeStatus))
	}

	private func actuallyWriteData(identifier: NSString, data: NSData, semaphore: dispatch_semaphore_t) -> BluetoothAsyncWriteState {
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
		
		//close()

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}
	}
}
