//
//  NXTCommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public typealias NXTCommandHandler = (NXTCommandResult) -> ()

public enum NXTCommandError: Error {
	case transportError(Error)
	case commandError(NXTStatus)
	case responseParseError
	case operationAborted
}

public enum NXTCommandResult {
	case error(NXTCommandError)
	case response(NXTResponse)
}

final class NXTCommandOperation: DeviceOperation {
	private let transport: DeviceTransport
	private let command: NXTCommand
	private let responseHandler: NXTCommandHandler

	private let isExecutingValue = SimpleAtomic<Bool>()
	private let isFinishedValue = SimpleAtomic<Bool>()
	
	override var isExecuting: Bool {
		return isExecutingValue.get()
	}

	override var isFinished: Bool {
		return isFinishedValue.get()
	}

	private func setExecuting(_ value: Bool) {
		willChangeValue(forKey: "isExecuting")
		isExecutingValue.set(value)
		didChangeValue(forKey: "isExecuting")
	}

	private func setFinished(_ value: Bool) {
		willChangeValue(forKey: "isFinished")
		isFinishedValue.set(value)
		didChangeValue(forKey: "isFinished")
	}

	init(transport: DeviceTransport, command: NXTCommand, isCritical: Bool, responseHandler: @escaping NXTCommandHandler) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init(isCritical: isCritical)
	}

	override func start() {
		if isCancelled {
		#if DEBUG
			print("Cancelling NXT operation...")
		#endif
			finishWithResult(.error(.operationAborted))
			return
		}

		setExecuting(true)

		let data = command.payloadData
		var dataLength = NSSwapHostShortToLittle(2 + UInt16(data.count))
		var type = command.telegramType
		var identifier = command.identifier
		var packet = Data()

	#if os(OSX)
		if transport is IOBluetoothDeviceTransport {
			withUnsafePointer(to: &dataLength) { ptr in
				packet.append(unsafeBitCast(ptr, to: UnsafePointer<UInt8>.self), count: MemoryLayout<UInt16>.size)
			}
		}
	#endif

		packet.append(&type, count: MemoryLayout<UInt8>.size)
		packet.append(&identifier, count: MemoryLayout<UInt8>.size)
		packet.append(data)

		do {
			try transport.writeData(packet) { error in
				self.finishWithResult(.error(.transportError(error)))
			}
		} catch {
			print("Cannot write packet data: \(error)")
			finishWithResult(.error(.transportError(error)))
		}
	}

	private func finishWithResult(_ result: NXTCommandResult) {
		if Thread.isMainThread {
			responseHandler(result)
		} else {
			DispatchQueue.main.sync {
				self.responseHandler(result)
			}
		}

		setExecuting(false)
		setFinished(true)
	}

	func canHandleResponseData(_ data: Data) -> Bool {
		if isCancelled {
			return false
		}

		let mainData: Data

	#if os(OSX)
		// Bluetooth responses are padded with the length.
		if transport is IOBluetoothDeviceTransport {
			assert(data.count >= 2)

			let length = Int(data.readUInt16AtIndex(0))
			mainData = data.subdata(in: 2..<data.count)

			assert(length == mainData.count)
		} else {
			mainData = data
		}
	#else
		mainData = data
	#endif

		guard let (commandCode, _) = processReplyWithResponseData(mainData) else {
			return false
		}

		return commandCode == command.identifier
	}

	func handleResponseData(_ data: Data) {
		let mainData: Data

	#if os(OSX)
		// Bluetooth responses are padded with the length.
		if transport is IOBluetoothDeviceTransport {
			assert(data.count >= 2)

			let length = Int(data.readUInt16AtIndex(0))
			mainData = data.subdata(in: 2..<data.count)

			assert(length == mainData.count)
		} else {
			mainData = data
		}
	#else
		mainData = data
	#endif

		guard let response = command.responseType.init(data: mainData, userInfo: command.responseInfo) as? NXTResponse else {
			print("Could not parse a response")
			finishWithResult(.error(.responseParseError))
			return
		}

		// FIXME: FileNotFound is returned in cases where we get correct data but we're at the very end of a file or file listing.
		// This is hacky, but it's safest/easiest to treat it as a successful response for now.
		let succeeded = response.status == .statusSuccess || response.status == .fileNotFound
		finishWithResult(succeeded ? .response(response) : .error(.commandError(response.status)))
	}
}
