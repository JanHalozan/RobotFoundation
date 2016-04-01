//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

final class EV3CommandOperation: NSOperation {
	private let transport: DeviceTransport
	private let command: EV3Command
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

	init(transport: DeviceTransport, command: EV3Command, responseHandler: NXTResponseHandler?) {
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

		let data: NSData

		// TODO: actually increment the message counter
		if let directCommand = command as? EV3DirectCommand {
			data = directCommand.formEV3PacketData(0, prependTotalLength: false)
		} else if let systemCommand = command as? EV3SystemCommand {
			data = systemCommand.formEV3PacketData(0)
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

	private func handleResponseData(data: NSData) {
		assert(NSThread.isMainThread())

		guard let response = command.responseType.init(data: data) else {
			print("Could not parse a response")
			isExecuting = false
			return
		}

		// Response handlers are optional.
		responseHandler?(response)

		isExecuting = false
	}
}
