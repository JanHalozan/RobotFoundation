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

	deinit {
		waitForOperations()
	}

	public func enqueueCommand(command: NXTCommand, responseHandler: NXTCommandHandler) {
		if transport.openState.get() == .Closed {
			print("No open transport, won't bother enqueuing the command.")
			responseHandler(.Error(.TransportError(kIOReturnAborted)))
			return
		}

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

	private var activeOperations: Int {
		var operationCount = 0
		for operation in operationQueue.operations where !operation.cancelled {
			operationCount += 1
		}
		return operationCount
	}
	
	public func waitForOperations() {
		while activeOperations > 0 {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05))
		}
	}

	override func handleData(data: NSData) {
		for operation in operationQueue.operations {
			if let commandOperation = operation as? NXTCommandOperation where commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
				return
			}
		}
	}

	override func wroteData() {
		guard let usbTransport = transport as? LegacyUSBDeviceTransport else {
			// Skip scheduling reads for Bluetooth transports.
			return
		}

		usbTransport.scheduleRead()
	}
}
