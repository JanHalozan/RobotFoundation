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

	public func enqueueCommand(command: NXTCommand, responseHandler: NXTResponseHandler) {
		let operation = NXTCommandOperation(transport: transport, command: command, responseHandler: responseHandler)
		operationQueue.addOperation(operation)
	}

	public func enqueueBarrier(handler: () -> ()) {
		let blockOperation = NSBlockOperation(block: {
			NSOperationQueue.mainQueue().addOperationWithBlock(handler)
		})

		for operation in operationQueue.operations {
			blockOperation.addDependency(operation)
		}

		operationQueue.addOperation(blockOperation)
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

	override func openedTransport() {
		for operation in operationQueue.operations {
			operation.willChangeValueForKey("isReady")
			operation.didChangeValueForKey("isReady")
		}
	}
}
