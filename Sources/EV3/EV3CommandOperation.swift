//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3ResponseError: Error {
	case incompleteResponse
	case invalidHeader
	case invalidPayload
}

public enum EV3CommandError: Error {
	case transportError(Error)
	case responseError(Error)
	case commandError
	case operationAborted
}

public enum EV3CommandResult {
	case error(EV3CommandError)
	case responseGroup(EV3ResponseGroup)
}

public typealias EV3ResponseHandler = (EV3CommandResult) -> ()

private func toDirectCommands(_ commands: [EV3Command]) -> [EV3DirectCommand] {
	var directCommands = [EV3DirectCommand]()
	for command in commands {
		if let directCommand = command as? EV3DirectCommand {
			directCommands.append(directCommand)
		} else {
			// System commands cannot be grouped, so these must be all direct commands.
			assertionFailure()
		}
	}
	return directCommands
}

final class EV3CommandGroupOperation: DeviceOperation {
	private let transport: DeviceTransport
	private let commands: [EV3Command]
	private let responseHandler: EV3ResponseHandler
	private let messageIndex: UInt16

	private static var messageCounter = UInt16()

	private let isExecutingValue = SimpleAtomic<Bool>()
	private let isFinishedValue = SimpleAtomic<Bool>()

	init(transport: DeviceTransport, commands: [EV3Command], isCritical: Bool, responseHandler: @escaping EV3ResponseHandler) {
		self.transport = transport
		self.commands = commands
		self.responseHandler = responseHandler
		self.messageIndex = EV3CommandGroupOperation.messageCounter
		EV3CommandGroupOperation.messageCounter = EV3CommandGroupOperation.messageCounter &+ 1
		super.init(isCritical: isCritical)
	}

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

	override func start() {
		if isCancelled {
		#if DEBUG
			print("Cancelling EV3 operation...")
		#endif
			finishWithResult(.error(.operationAborted))
			return
		}

		setExecuting(true)

		let data: Data

		if let systemCommand = commands.first as? EV3SystemCommand {
			// If the first command is a system command, it should be the only command as we can't batch system commands.
			assert(commands.count == 1)
			data = systemCommand.formEV3PacketData(messageIndex)
		} else if commands.first is EV3DirectCommand {
			let directCommands = toDirectCommands(commands)
			data = formEV3PacketDataForCommands(directCommands, messageCounter: messageIndex)
		} else {
			fatalError()
		}

		do {
			try transport.writeData(data) { error in
				self.finishWithResult(.error(.transportError(error)))
			}
		} catch {
			print("Cannot write packet data: \(error)")
			finishWithResult(.error(.transportError(error)))
		}
	}

	private func finishWithResult(_ result: EV3CommandResult) {
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
			NSLog("\(#function): cannot handle cancelled operation...")
			return false
		}

		let headerResponse = processGenericResponseForData(data)
		guard case let .success(length: _, messageCounter: messageCounter, replyType: _) = headerResponse else {
			NSLog("\(#function): cannot handle operation: \(headerResponse)")
			return false
		}

		guard messageCounter == messageIndex else {
			NSLog("\(#function): cannot handle mismatched response...")
			return false
		}

		return true
	}

	func handleResponseData(_ data: Data) {
		guard data.count >= 5 else {
			print("Responses should be at least 5 bytes in length")
			finishWithResult(.error(.responseError(EV3ResponseError.incompleteResponse)))
			return
		}

		guard case let .success(length: length, messageCounter: messageCounter, replyType: replyType) = processGenericResponseForData(data) else {
			print("Could not parse the generic response header")
			finishWithResult(.error(.responseError(EV3ResponseError.invalidHeader)))
			return
		}

		assert(messageCounter == messageIndex)
		assert(data.count >= 5)
		assert(Int(length) <= data.count - 2)

		// For HID transports, `data` is a fixed size buffer. Truncate it to the actual length.
		var restOfData = data.subdata(in: 5..<(Int(length) + 2))
		var responses = [EV3Response]()

		for command in commands {
			guard let response = command.responseType.init(data: restOfData, userInfo: command.responseInfo) as? EV3Response else {
				print("Could not parse a response")
				finishWithResult(.error(.responseError(EV3ResponseError.invalidPayload)))
				return
			}

			responses.append(response)

			restOfData = restOfData.subdata(in: response.responseLength..<restOfData.count)
		}

		let responseGroup = EV3ResponseGroup(length: length, messageCounter: messageCounter, responses: responses)
		finishWithResult(replyType.isError ? .error(.commandError) : .responseGroup(responseGroup))
	}
}
