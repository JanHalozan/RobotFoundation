//
//  NXTCommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

final class NXTCommandOperation: NSOperation {
	private let transport: DeviceTransport
	private let command: NXTCommand
	private let responseHandler: NXTResponseHandler?

	private var isExecuting = false {
		willSet {
			willChangeValueForKey("isExecuting")
			willChangeValueForKey("isFinished")
		}
		didSet {
			didChangeValueForKey("isExecuting")
			didChangeValueForKey("isFinished")
		}
	}

	init(transport: DeviceTransport, command: NXTCommand, responseHandler: NXTResponseHandler?) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init()
	}

	override var concurrent: Bool {
		return true
	}

	override var executing: Bool {
		return isExecuting
	}

	override var finished: Bool {
		return !isExecuting
	}

	override var ready: Bool {
		return super.ready && transport.openState == .Opened
	}

	override func start() {
		guard NSThread.isMainThread() else {
			dispatch_sync(dispatch_get_main_queue()) {
				self.start()
			}
			return
		}

		let data = command.payloadData
		var dataLength = NSSwapHostShortToLittle(2 + UInt16(data.length))
		var type = command.telegramType
		var identifier = command.identifier

		let packet = NSMutableData()

	#if os(OSX)
		if transport is IOBluetoothDeviceTransport {
			packet.appendBytes(&dataLength, length: sizeof(UInt16))
		}
	#endif

		packet.appendBytes(&type, length: sizeof(UInt8))
		packet.appendBytes(&identifier, length: sizeof(UInt8))
		packet.appendData(data)

		do {
			try transport.writeData(packet, errorHandler: {
				self.handleErrorResponse()
			})
		} catch {
			print("Cannot write packet data: \(error)")
		}

		isExecuting = true
	}

	private func handleErrorResponse() {
		assert(NSThread.isMainThread())
		isExecuting = false
	}

	func canHandleResponseData(data: NSData) -> Bool {
		return true
	}

	func handleResponseData(data: NSData) {
		let fullData: NSData

		/*
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
*/
			fullData = data
//		}

		guard let response = command.responseType.init(data: fullData, userInfo: command.responseInfo) else {
			print("Could not parse a response")
			isExecuting = false
			return
		}

		// Response handlers are optional.
		responseHandler?(response)
		isExecuting = false
	}
}
