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

	private let isExecuting = AtomicBool()
	private let isFinished = AtomicBool()
	private let isCancelled = AtomicBool()
	
	override var executing: Bool {
		return isExecuting.get()
	}

	override var finished: Bool {
		return isFinished.get()
	}

	override var cancelled: Bool {
		return isCancelled.get()
	}

	override func cancel() {
		super.cancel()
		setExecuting(false)
		setFinished(false)
		setCancelled(true)
	}

	private func setExecuting(value: Bool) {
		willChangeValueForKey("isExecuting")
		isExecuting.set(value)
		didChangeValueForKey("isExecuting")
	}

	private func setFinished(value: Bool) {
		willChangeValueForKey("isFinished")
		isFinished.set(value)
		didChangeValueForKey("isFinished")
	}

	private func setCancelled(value: Bool) {
		willChangeValueForKey("isCancelled")
		isCancelled.set(value)
		didChangeValueForKey("isCancelled")
	}

	init(transport: DeviceTransport, command: NXTCommand, responseHandler: NXTResponseHandler?) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init()
	}

	override var ready: Bool {
		assert(NSThread.isMainThread())
		return super.ready && transport.openState == .Opened
	}

	override func start() {
		guard NSThread.isMainThread() else {
			dispatch_sync(dispatch_get_main_queue()) {
				self.start()
			}
			return
		}

		setExecuting(true)

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
			handleErrorResponse()
		}
	}

	private func handleErrorResponse() {
		assert(NSThread.isMainThread())
		setExecuting(false)
		setFinished(true)
	}

	func canHandleResponseData(data: NSData) -> Bool {
		return true
	}

	func handleResponseData(data: NSData) {
		let mainData: NSData

		// Bluetooth responses are padded with the length.
		if transport is IOBluetoothDeviceTransport {
			assert(data.length >= 2)

			let length = Int(data.readUInt16AtIndex(0))
			mainData = data.subdataWithRange(NSMakeRange(2, data.length - 2))

			assert(length == mainData.length)
		} else {
			mainData = data
		}

		guard let response = command.responseType.init(data: mainData, userInfo: command.responseInfo) else {
			print("Could not parse a response")
			setExecuting(false)
			setFinished(true)
			return
		}

		// Response handlers are optional.
		responseHandler?(response)
		setExecuting(false)
		setFinished(true)
	}
}
