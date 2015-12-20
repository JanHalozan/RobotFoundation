//
//  NXTCommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

final class NXTCommandOperation: NSOperation {
	let transport: DeviceTransport
	private let command: NXTCommand
	private let responseHandler: NXTResponseHandler?

	init(transport: DeviceTransport, command: NXTCommand, responseHandler: NXTResponseHandler?) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init()
	}

	override var concurrent: Bool {
		return true
	}

	override func start() {
		assert(NSThread.isMainThread())

		let data = command.payloadData
		var dataLength = NSSwapHostShortToLittle(2 + UInt16(data.length))
		var type = command.telegramType
		var identifier = command.identifier

		let packet = NSMutableData()

		#if os(OSX)
		// TODO: should this actually check for USB transport?
		if transport is IOBluetoothDeviceTransport {
			packet.appendBytes(&dataLength, length: sizeof(UInt16))
		}
		#endif

		packet.appendBytes(&type, length: sizeof(UInt8))
		packet.appendBytes(&identifier, length: sizeof(UInt8))
		packet.appendData(data)

		do {
			try transport.writeData(data)
		} catch {
			print("Cannot write packet data: \(error)")
		}
	}

	func handleResponseData(data: NSData) {
		// Response handlers are optional.
		guard let responseHandler = self.responseHandler else {
			return
		}

		let fullData: NSData

		if transport is IOUSBDeviceTransport {
			// USB packets are missing with some data we have to trim.
			let fullMutableData = NSMutableData()

			var bytesRead = data.length
			var empty = UInt8()

			//TODO: should this really be a 32-bit int?
			fullMutableData.appendBytes(&bytesRead, length: sizeof(UInt32))
			fullMutableData.appendBytes(&empty, length: sizeof(UInt8))
			fullMutableData.appendData(data)

			fullData = fullMutableData.copy() as! NSData
		} else {
			fullData = data
		}

		guard let response = command.responseType.init(data: fullData) else {
			print("Could not parse a response")
			return
		}

		responseHandler(response)
	}
}
