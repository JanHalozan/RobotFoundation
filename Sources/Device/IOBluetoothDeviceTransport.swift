//
//  IOBluetoothDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation
import IOBluetooth

/* supports RFCOMM communication */
final class IOBluetoothDeviceTransport: DeviceTransport {
	 /* use with care */
	let bluetoothDevice: IOBluetoothDevice

	private var channel: IOBluetoothRFCOMMChannel?

	init(var address: BluetoothDeviceAddress) {
		self.bluetoothDevice = IOBluetoothDevice(address: &address)
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		self.bluetoothDevice = bluetoothDevice
	}

	override func open() throws -> Bool {
		let status = bluetoothDevice.openConnection(self)

		guard status == kIOReturnSuccess else {
			throw status
		}

		return true
	}

	override func close() {
		guard isOpen else {
			return
		}

		channel?.closeChannel()
		bluetoothDevice.closeConnection()

		// Invoke delegate.
		closed()
	}

	override func writeData(data: NSData) throws -> Bool {
		guard let channel = channel else {
			return false
		}

		var bytes = data.bytes
		var conn = unsafeBitCast(self, UInt8.self)
		let status = channel.writeAsync(&bytes, length: UInt16(data.length), refcon: &conn)

		guard status == kIOReturnSuccess else {
			throw status
		}

		return true
	}

	@objc func connectionComplete(device: IOBluetoothDevice, var status: IOReturn) {
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

	@objc func rfcommChannelOpenComplete(channel: IOBluetoothRFCOMMChannel, status: IOReturn) {
		guard status == kIOReturnSuccess else {
			failedToOpenWithError(status)
			return
		}

		opened()
	}

	@objc func rfcommChannelData(channel: IOBluetoothRFCOMMChannel, data: UnsafePointer<Void>, length: size_t) {
		let data = NSData(bytes: data, length: length)
		receivedData(data)
	}

	@objc func rfcommChannelClosed(channel: IOBluetoothRFCOMMChannel) {
		close()
	}
}
