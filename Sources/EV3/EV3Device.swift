//
//  EV3Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

// TODO: This is mostly a copy of NXTDevice. Once we figure out what works and doesn't we should refactor things.
public final class EV3Device: Device {
	private lazy var operationQueue: NSOperationQueue = {
		let operationQueue = NSOperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	public func enqueueCommand(command: EV3Command, responseHandler: NXTResponseHandler) {
		let operation = EV3CommandOperation(transport: transport, command: command, responseHandler: responseHandler)
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

	override func wroteData() { }

	override func openedTransport() {
		for operation in operationQueue.operations {
			operation.willChangeValueForKey("isReady")
			operation.didChangeValueForKey("isReady")
		}
	}
}

