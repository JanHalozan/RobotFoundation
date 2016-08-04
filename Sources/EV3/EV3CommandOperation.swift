//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public typealias EV3ResponseHandler = EV3ResponseGroup -> ()

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

final class EV3CommandGroupOperation: NSOperation {
	private let transport: DeviceTransport
	private let commands: [EV3Command]
	private let responseHandler: EV3ResponseHandler?
	private let messageIndex: UInt16

	private static var messageCounter = UInt16()

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

	init(transport: DeviceTransport, commands: [EV3Command], responseHandler: EV3ResponseHandler?) {
		self.transport = transport
		self.commands = commands
		self.responseHandler = responseHandler
		self.messageIndex = EV3CommandGroupOperation.messageCounter
		EV3CommandGroupOperation.messageCounter = EV3CommandGroupOperation.messageCounter &+ 1
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

		// TODO: actually increment the message counter

		do {
			try transport.writeData(data, errorHandler: {
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
		guard let (_, messageCounter, _) = processGenericResponseForData(data) else {
			return false
		}

		return messageCounter == messageIndex
	}

	func handleResponseData(data: NSData) {
		assert(NSThread.isMainThread())

		guard data.length >= 5 else {
			debugPrint("Responses should be at least 5 in length")
			isExecuting = false
			return
		}

		guard let (length, messageCounter, replyType) = processGenericResponseForData(data) else {
			debugPrint("Could not parse the generic response header")
			isExecuting = false
			return
		}

		assert(messageCounter == messageIndex)
		assert(data.length >= 5)

		var restOfData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
		var responses = [EV3Response]()

		for command in commands {
			guard let response = command.responseType.init(data: restOfData, userInfo: command.responseInfo) as? EV3Response else {
				print("Could not parse a response")
				isExecuting = false
				return
			}

			responses.append(response)

			restOfData = restOfData.subdataWithRange(NSMakeRange(response.responseLength, restOfData.length - response.responseLength))
		}

		let responseGroup = EV3ResponseGroup(length: length, replyType: replyType, messageCounter: messageCounter, responses: responses)

		// Response handlers are optional.
		responseHandler?(responseGroup)

		isExecuting = false
	}
}
