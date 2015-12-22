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

	private var isExecuting = false

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
		return super.ready && transport.isOpen
	}

	override func start() {
		guard NSThread.isMainThread() else {
			dispatch_sync(dispatch_get_main_queue()) {
				self.start()
			}
			return
		}

		// TODO: actually increment the message counter
		let data = command.formEV3PacketData(0, prependTotalLength: false)

		do {
			try transport.writeData(data)
		} catch {
			print("Cannot write packet data: \(error)")
		}

		willChangeValueForKey("isExecuting")
		willChangeValueForKey("isFinished")

		isExecuting = true

		didChangeValueForKey("isExecuting")
		didChangeValueForKey("isFinished")
	}

	func handleResponseData(data: NSData) {
		// Response handlers are optional.
		guard let responseHandler = self.responseHandler else {
			return
		}

		// TODO: handle differences in USB packets
		let fullData = data

		guard let response = command.responseType.init(data: fullData) else {
			print("Could not parse a response")
			return
		}

		responseHandler(response)

		willChangeValueForKey("isExecuting")
		willChangeValueForKey("isFinished")

		isExecuting = false

		didChangeValueForKey("isExecuting")
		didChangeValueForKey("isFinished")
	}
}
