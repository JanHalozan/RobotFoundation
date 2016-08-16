//
//  NXTCommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public typealias NXTCommandHandler = (NXTCommandResult) -> ()

public enum NXTCommandError: ErrorType {
	case TransportError(ErrorType)
	case CommandError(NXTStatus)
	case ResponseParseError
}

public enum NXTCommandResult {
	case Error(NXTCommandError)
	case Response(NXTResponse)
}

final class NXTCommandOperation: DeviceOperation {
	private let transport: DeviceTransport
	private let command: NXTCommand
	private let responseHandler: NXTCommandHandler

	private let isExecuting = SimpleAtomic<Bool>()
	private let isFinished = SimpleAtomic<Bool>()
	
	override var executing: Bool {
		return isExecuting.get()
	}

	override var finished: Bool {
		return isFinished.get()
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

	init(transport: DeviceTransport, command: NXTCommand, isCritical: Bool, responseHandler: NXTCommandHandler) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init(isCritical: isCritical)
	}

	override func start() {
		if cancelled {
		#if DEBUG
			print("Cancelling NXT operation...")
		#endif
			finishWithResult(.Error(.TransportError(kIOReturnAborted)))
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
			try transport.writeData(packet) { error in
				self.finishWithResult(.Error(.TransportError(error)))
			}
		} catch {
			print("Cannot write packet data: \(error)")
			finishWithResult(.Error(.TransportError(error)))
		}
	}

	private func finishWithResult(result: NXTCommandResult) {
		if NSThread.isMainThread() {
			responseHandler(result)
		} else {
			dispatch_sync(dispatch_get_main_queue()) {
				self.responseHandler(result)
			}
		}

		setExecuting(false)
		setFinished(true)
	}

	func canHandleResponseData(data: NSData) -> Bool {
		if cancelled {
			return false
		}

		guard let (commandCode, _) = processReplyWithResponseData(data) else {
			return false
		}

		return commandCode == command.identifier
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

		guard let response = command.responseType.init(data: mainData, userInfo: command.responseInfo) as? NXTResponse else {
			print("Could not parse a response")
			finishWithResult(.Error(.ResponseParseError))
			return
		}

		// FIXME: FileNotFound is returned in cases where we get correct data but we're at the very end of a file or file listing.
		// This is hacky, but it's safest/easiest to treat it as a successful response for now.
		let succeeded = response.status == .StatusSuccess || response.status == .FileNotFound
		finishWithResult(succeeded ? .Response(response) : .Error(.CommandError(response.status)))
	}
}
