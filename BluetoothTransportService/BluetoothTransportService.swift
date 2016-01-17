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

private enum BluetoothAsyncOpenState {
	case Opening(IOBluetoothDevice)
	case AlreadyConnected
	case Error(Int)
}

private enum BluetoothAsyncWriteState {
	case Writing
	case Error(Int)
}

final class BluetoothTransportService : NSObject, XPCTransportServiceProtocol, IOBluetoothRFCOMMChannelDelegate {
	private var bluetoothDevice: IOBluetoothDevice?
	private var channel: IOBluetoothRFCOMMChannel?

	private var connectingChannels = Set<IOBluetoothRFCOMMChannel>()

	private var activeClients = 0

	private var openSemaphore = dispatch_semaphore_create(0)
	private var openStatus: IOReturn?

	private var writeSemaphore = dispatch_semaphore_create(0)
	private var receivedData: NSData?

	private var currentIdentifier: String? {
		assert(NSThread.isMainThread())
		return bluetoothDevice?.addressString
	}

	func open(identifier: NSString, handler: Int -> ()) {
		// Should be kIOReturnInvalid which Swift doesn't import
		var openState = BluetoothAsyncOpenState.Error(1)

		dispatch_sync(dispatch_get_main_queue()) {
			openState = self.actuallyOpenWithIdentifier(identifier)
		}

		switch openState {
		case .AlreadyConnected:
			handler(Int(kIOReturnSuccess))
			return
		case .Error(let errorCode):
			handler(errorCode)
			return
		case .Opening:
			// continue on
			break
		}

		guard case BluetoothAsyncOpenState.Opening(let device) = openState else {
			assertionFailure()
			return
		}

		guard dispatch_semaphore_wait(openSemaphore, tenSecondTimeout()) == 0 else {
			// Should be kIOReturnTimeout which Swift can't import
			handler(Int(1))
			return
		}

		guard let openStatus = openStatus else {
			// Should be kIOReturnNotFound which Swift can't import
			handler(Int(1))
			return
		}

		if openStatus == kIOReturnSuccess {
			// We actually did it.
			dispatch_sync(dispatch_get_main_queue()) {
				self.bluetoothDevice = device
				self.activeClients++
			}
		}

		handler(Int(openStatus))
	}

	private func actuallyOpenWithIdentifier(identifier: NSString) -> BluetoothAsyncOpenState {
		if currentIdentifier == nil {
			assert(activeClients == 0)
			return openNewDevice(identifier)
		} else if currentIdentifier! == identifier {
			activeClients += 1
			return .AlreadyConnected
		} else {
			debugPrint("Tried to open a device while one was already open.")
			return .Error(1)
		}
	}

	private func openNewDevice(identifier: NSString) -> BluetoothAsyncOpenState {
		let device = IOBluetoothDevice(addressString: identifier as String)
		let openResult = Int(device.openConnection(self))

		guard openResult == Int(kIOReturnSuccess) else {
			return .Error(openResult)
		}

		return .Opening(device)
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
			handler(Int(1))
			return
		}

		guard currentIdentifier == identifier else {
			debugPrint("Device mismatch.")
			handler(Int(1))
			return
		}

		activeClients -= 1
		assert(activeClients >= 0)

		if activeClients == 0 {
			assert(channel != nil)
			channel?.closeChannel()
			bluetoothDevice?.closeConnection()

			channel = nil
			bluetoothDevice = nil
		}

		handler(Int(kIOReturnSuccess))
	}

	func writeData(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		// Should be kIOReturnInvalid which Swift doesn't import
		var writeState = BluetoothAsyncWriteState.Error(1)

		dispatch_sync(dispatch_get_main_queue()) {
			writeState = self.actuallyWriteData(identifier, data: data)
		}

		switch writeState {
		case .Error(let errorCode):
			handler(nil, errorCode)
			return
		case .Writing:
			// continue on
			break
		}

		guard dispatch_semaphore_wait(writeSemaphore, tenSecondTimeout()) == 0 else {
			// Should be kIOReturnTimeout which Swift doesn't import
			handler(nil, Int(1))
			return
		}

		guard let receivedData = receivedData else {
			// Should be kIOReturnNotFound which Swift doesn't import
			handler(nil, Int(1))
			return
		}

		handler(receivedData, Int(kIOReturnSuccess))
	}

	private func actuallyWriteData(identifier: NSString, data: NSData) -> BluetoothAsyncWriteState {
		guard let channel = channel else {
			return .Error(1)
		}

		var array = [UInt8](count: data.length, repeatedValue: 0)
		data.getBytes(&array, length: data.length)
		let status = channel.writeAsync(&array, length: UInt16(data.length), refcon: nil)

		guard status == kIOReturnSuccess else {
			return .Error(Int(status))
		}

		return .Writing
	}

	@objc func connectionComplete(device: IOBluetoothDevice, status: IOReturn) {
		assert(NSThread.isMainThread())

		guard status == kIOReturnSuccess else {
			finishedOpenWithError(status)
			return
		}

		let uuid = IOBluetoothSDPUUID(UUID16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		guard let record = device.getServiceRecordForUUID(uuid) else {
			// Should be kIOReturnNotFound which Swift doesn't import
			finishedOpenWithError(IOReturn(1))
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
			// Should be kIOReturnNotFound which Swift doesn't import
			finishedOpenWithError(IOReturn(1))
			return
		}

		connectingChannels.insert(theNewChannel)
	}

	private func finishedOpenWithError(error: IOReturn) {
		openStatus = error
		dispatch_semaphore_signal(openSemaphore)
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

		receivedData = NSData(bytes: dataPointer, length: dataLength)
		dispatch_semaphore_signal(writeSemaphore)
	}

	@objc func rfcommChannelClosed(rfcommChannel: IOBluetoothRFCOMMChannel!) {
		assert(NSThread.isMainThread())
		
		//close()

		if let rfcommChannel = rfcommChannel {
			connectingChannels.remove(rfcommChannel)
		}
	}
}
