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

	public func enqueueCommand(command: EV3Command, responseHandler: EV3ResponseHandler) {
		enqueueCommands([command], responseHandler: responseHandler)
	}

	public func enqueueCommands(commands: [EV3Command], responseHandler: EV3ResponseHandler) {
		if transport.openState.get() == .Closed {
			print("No open transport, won't bother enqueuing the commands.")
			responseHandler(.Error(.TransportError(kIOReturnAborted)))
			return
		}
		
		// TODO: system commands cannot be grouped
		let operation = EV3CommandGroupOperation(transport: transport, commands: commands, responseHandler: responseHandler)
		operationQueue.addOperation(operation)
	}

	public func enqueueBarrier(handler: () -> ()) {
		let blockOperation = NSBlockOperation(block: {
			NSOperationQueue.mainQueue().addOperationWithBlock(handler)
		})

		operationQueue.addOperation(blockOperation)
	}

	private var activeOperations: Int {
		var operationCount = 0
		for operation in operationQueue.operations where !operation.cancelled {
			operationCount += 1
		}
		return operationCount
	}

	public func waitForOperations() {
		while activeOperations > 0 {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: .distantFuture())
		}
	}

	override func wroteData() { }

	override func handleData(data: NSData) {
		for operation in operationQueue.operations {
			if let commandOperation = operation as? EV3CommandGroupOperation where commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
			}
		}
	}

	override func failedToOpenTransport() {
		assert(NSThread.isMainThread())
		operationQueue.cancelAllOperations()
	}

	override func openedTransport() {
		for operation in operationQueue.operations {
			operation.willChangeValueForKey("isReady")
			operation.didChangeValueForKey("isReady")
		}
	}

	public override func close() {
		waitForOperations()
		super.close()
	}
}

