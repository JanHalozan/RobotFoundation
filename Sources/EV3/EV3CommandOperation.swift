//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3ResponseError: ErrorType {
	case IncompleteResponse
	case InvalidHeader
	case InvalidPayload
}

public enum EV3CommandError: ErrorType {
	case TransportError(ErrorType)
	case ResponseError(ErrorType)
	case CommandError
}

public enum EV3CommandResult {
	case Error(EV3CommandError)
	case ResponseGroup(EV3ResponseGroup)
}

public typealias EV3ResponseHandler = (EV3CommandResult) -> ()

private func toDirectCommands(commands: [EV3Command]) -> [EV3DirectCommand] {
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

	private let isExecuting = SimpleAtomic<Bool>()
	private let isFinished = SimpleAtomic<Bool>()

	init(transport: DeviceTransport, commands: [EV3Command], isCritical: Bool, responseHandler: EV3ResponseHandler) {
		self.transport = transport
		self.commands = commands
		self.responseHandler = responseHandler
		self.messageIndex = EV3CommandGroupOperation.messageCounter
		EV3CommandGroupOperation.messageCounter = EV3CommandGroupOperation.messageCounter &+ 1
		super.init(isCritical: isCritical)
	}

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

	override func start() {
		if cancelled {
		#if DEBUG
			print("Cancelling EV3 operation...")
		#endif
			finishWithResult(.Error(.TransportError(kIOReturnAborted)))
			return
		}

		setExecuting(true)

		let data: NSData

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
				self.finishWithResult(.Error(.TransportError(error)))
			}
		} catch {
			print("Cannot write packet data: \(error)")
			finishWithResult(.Error(.TransportError(error)))
		}
	}

	private func finishWithResult(result: EV3CommandResult) {
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

		guard let (_, messageCounter, _) = processGenericResponseForData(data) else {
			return false
		}

		return messageCounter == messageIndex
	}

	func handleResponseData(data: NSData) {
		guard data.length >= 5 else {
			print("Responses should be at least 5 bytes in length")
			finishWithResult(.Error(.ResponseError(EV3ResponseError.IncompleteResponse)))
			return
		}

		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			print("Could not parse the generic response header")
			finishWithResult(.Error(.ResponseError(EV3ResponseError.InvalidHeader)))
			return
		}

		assert(messageCounter == messageIndex)
		assert(data.length >= 5)

		var restOfData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
		var responses = [EV3Response]()

		for command in commands {
			guard let response = command.responseType.init(data: restOfData, userInfo: command.responseInfo) as? EV3Response else {
				print("Could not parse a response")
				finishWithResult(.Error(.ResponseError(EV3ResponseError.InvalidPayload)))
				return
			}

			responses.append(response)

			restOfData = restOfData.subdataWithRange(NSMakeRange(response.responseLength, restOfData.length - response.responseLength))
		}

		let responseGroup = EV3ResponseGroup(length: length, messageCounter: messageCounter, responses: responses)
		finishWithResult(replyType.isError ? .Error(.CommandError) : .ResponseGroup(responseGroup))
	}
}
