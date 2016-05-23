//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public typealias EV3ResponseHandler = EV3ResponseGroup -> ()

final class EV3CommandOperation: NSOperation {
	private let transport: DeviceTransport
	private let command: EV3Command
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

	init(transport: DeviceTransport, command: EV3Command, responseHandler: EV3ResponseHandler?) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		self.messageIndex = EV3CommandOperation.messageCounter
		EV3CommandOperation.messageCounter = EV3CommandOperation.messageCounter &+ 1
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

		// TODO: actually increment the message counter
		if let directCommand = command as? EV3DirectCommand {
			data = directCommand.formEV3PacketData(messageIndex, prependTotalLength: false)
		} else if let systemCommand = command as? EV3SystemCommand {
			data = systemCommand.formEV3PacketData(messageIndex)
		} else {
			fatalError()
		}

		do {
			try transport.writeData(data, handler: { resultData in
				self.handleResponseData(resultData)
			}, errorHandler: {
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

		guard data.length >= 0 else {
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

		let restOfData = data.subdataWithRange(NSMakeRange(5, data.length - 5))

		guard let response = command.responseType.init(data: restOfData, userInfo: command.responseInfo) as? EV3Response else {
			print("Could not parse a response")
			isExecuting = false
			return
		}

		let responseGroup = EV3ResponseGroup(length: length, replyType: replyType, messageCounter: messageCounter, responses: [response])

		// Response handlers are optional.
		responseHandler?(responseGroup)

		isExecuting = false
	}
}
