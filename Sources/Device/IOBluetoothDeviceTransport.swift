//
//  IOBluetoothDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

#if os(OSX)

import Foundation
import IOBluetooth

/* supports RFCOMM communication */
final class IOBluetoothDeviceTransport: DeviceTransport, IOBluetoothRFCOMMChannelDelegate {
	 /* use with care */
	let bluetoothDevice: IOBluetoothDevice

	private var channel: IOBluetoothRFCOMMChannel?

	init(var address: BluetoothDeviceAddress) {
		self.bluetoothDevice = IOBluetoothDevice(address: &address)
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		self.bluetoothDevice = bluetoothDevice
	}

	override func open() throws {
		let status = bluetoothDevice.openConnection(self)

		guard status == kIOReturnSuccess else {
			throw status
		}
	}

	override func close() {
		guard isOpen else {
			return
		}

		assert(channel != nil)
		channel?.closeChannel()
		bluetoothDevice.closeConnection()

		// Invoke delegate.
		closed()
	}

	override func writeData(data: NSData, handler: NSData -> ()) throws {
		guard let channel = channel else {
			throw IOReturn(1)
		}

		var array = [UInt8](count: data.length, repeatedValue: 0)
		data.getBytes(&array, length: data.length)
		let status = channel.writeAsync(&array, length: UInt16(data.length), refcon: nil)

		guard status == kIOReturnSuccess else {
			throw status
		}
	}

	@objc func connectionComplete(device: IOBluetoothDevice, var status: IOReturn) {
		assert(NSThread.isMainThread())

		guard status == kIOReturnSuccess else {
			failedToOpenWithError(status)
			return
		}

		var channelID = BluetoothRFCOMMChannelID()

		let uuid = IOBluetoothSDPUUID(UUID16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		let record = bluetoothDevice.getServiceRecordForUUID(uuid)

		status = record.getRFCOMMChannelID(&channelID)

		guard status == kIOReturnSuccess else {
			failedToOpenWithError(status)
			return
		}

		var channel: IOBluetoothRFCOMMChannel?
		status = bluetoothDevice.openRFCOMMChannelAsync(&channel, withChannelID: channelID, delegate: self)

		guard status == kIOReturnSuccess else {
			self.channel = nil
			failedToOpenWithError(status)
			return
		}

		self.channel = channel
	}

	@objc func rfcommChannelOpenComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
		assert(NSThread.isMainThread())

		guard error == kIOReturnSuccess else {
			failedToOpenWithError(error)
			return
		}

		opened()
	}

	@objc func rfcommChannelData(rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutablePointer<Void>, length dataLength: Int) {
		assert(NSThread.isMainThread())

		let data = NSData(bytes: dataPointer, length: dataLength)
//		receivedData(data)
	}

	@objc func rfcommChannelClosed(rfcommChannel: IOBluetoothRFCOMMChannel!) {
		assert(NSThread.isMainThread())
		
		close()
	}
}

#endif
