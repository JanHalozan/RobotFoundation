//
//  BluetoothTransportService.m
//  BluetoothTransportService
//
//  Created by Matt on 12/26/15.
//

import Foundation
import IOBluetooth

final class BluetoothTransportService : NSObject, XPCTransportServiceProtocol {
	private let connection: NSXPCConnection
	private var bluetoothDevice: IOBluetoothDevice?

	private var openSemaphore = dispatch_semaphore_create(0)
	private var openStatus: IOReturn?

	private var writeSemaphore = dispatch_semaphore_create(0)
	private var receivedData: NSData?

	private var channel: IOBluetoothRFCOMMChannel?

	init(connection: NSXPCConnection) {
		self.connection = connection
	}

	func open(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			self.bluetoothDevice = IOBluetoothDevice(addressString: identifier as String)
			let status = self.bluetoothDevice!.openConnection(self)

			guard status == kIOReturnSuccess else {
				handler(Int(status))
				return
			}
		}

		dispatch_semaphore_wait(openSemaphore, DISPATCH_TIME_FOREVER)
		handler(Int(openStatus!))
	}

	func close(identifier: NSString, handler: Int -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			assert(self.channel != nil)
			self.channel?.closeChannel()
			self.bluetoothDevice?.closeConnection()
		}

		handler(Int(kIOReturnSuccess))
	}

	func writeData(identifier: NSString, data: NSData, handler: (NSData?, Int) -> ()) {
		dispatch_sync(dispatch_get_main_queue()) {
			guard let channel = self.channel else {
				handler(nil, 1)
				return
			}

			var array = [UInt8](count: data.length, repeatedValue: 0)
			data.getBytes(&array, length: data.length)
			let status = channel.writeAsync(&array, length: UInt16(data.length), refcon: nil)

			guard status == kIOReturnSuccess else {
				handler(nil, Int(status))
				return
			}
		}

		dispatch_semaphore_wait(writeSemaphore, DISPATCH_TIME_FOREVER)
		handler(receivedData!, Int(kIOReturnSuccess))
	}

	@objc func connectionComplete(device: IOBluetoothDevice, var status: IOReturn) {
		assert(NSThread.isMainThread())

		guard status == kIOReturnSuccess else {
			//failedToOpenWithError(status)
			return
		}

		var channelID = BluetoothRFCOMMChannelID()

		let uuid = IOBluetoothSDPUUID(UUID16: BluetoothSDPUUID16(kBluetoothSDPUUID16ServiceClassSerialPort.rawValue))
		let record = bluetoothDevice!.getServiceRecordForUUID(uuid)

		status = record.getRFCOMMChannelID(&channelID)

		guard status == kIOReturnSuccess else {
			//failedToOpenWithError(status)
			return
		}

		var channel: IOBluetoothRFCOMMChannel?
		status = bluetoothDevice!.openRFCOMMChannelAsync(&channel, withChannelID: channelID, delegate: self)

		guard status == kIOReturnSuccess else {
			self.channel = nil
			//failedToOpenWithError(status)
			return
		}

		self.channel = channel
	}

	@objc func rfcommChannelOpenComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
		assert(NSThread.isMainThread())

		openStatus = error
		dispatch_semaphore_signal(openSemaphore)
	}

	@objc func rfcommChannelData(rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutablePointer<Void>, length dataLength: Int) {
		assert(NSThread.isMainThread())

		receivedData = NSData(bytes: dataPointer, length: dataLength)
		dispatch_semaphore_signal(writeSemaphore)
	}

	@objc func rfcommChannelClosed(rfcommChannel: IOBluetoothRFCOMMChannel!) {
		assert(NSThread.isMainThread())
		
		//close()
	}
}
