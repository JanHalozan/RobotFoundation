//
//  NXTDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class NXTDevice: Device {
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
		// TODO: might need this for NXT support
		/*
		if let usbTransport = transport as? IOUSBDeviceTransport {
			do {
				try usbTransport.scheduleRead()
			} catch {
				print("Cannot schedule read: \(error)")
			}
		}
		*/
	}

	private var currentlyExecutingOperation: NXTCommandOperation? {
		for operation in operationQueue.operations {
			if operation.executing {
				return operation as? NXTCommandOperation
			}
		}

		return nil
	}
}
