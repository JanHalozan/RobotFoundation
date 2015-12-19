//
//  EV3Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

// TODO: This is mostly a copy of NXTDevice. Once we figure out what works and doesn't we should refactor things.
final class EV3Device: Device {
	private lazy var operationQueue: NSOperationQueue = {
		let operationQueue = NSOperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	func enqueueCommand(command: NXTCommand, responseHandler: NXTResponseHandler) {
		let operation = NXTCommandOperation(transport: transport, command: command, responseHandler: responseHandler)
		operationQueue.addOperation(operation)
	}

	override func wroteData() {
		if let usbTransport = transport as? IOUSBDeviceTransport {
			do {
				try usbTransport.scheduleRead()
			} catch {
				print("Cannot schedule read: \(error)")
			}
		}
	}

	private var currentlyExecutingOperation: NXTCommandOperation? {
		for operation in operationQueue.operations {
			if operation.executing {
				return operation as? NXTCommandOperation
			}
		}

		return nil
	}

	override func receivedData(data: NSData) {
		guard let operation = currentlyExecutingOperation else {
			assertionFailure("How did we get data if an operation isn't executing?")
			return
		}

		operation.handleResponseData(data)
	}
}

