//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	private lazy var operationQueue: NSOperationQueue = {
		let operationQueue = NSOperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	init(transport: DeviceTransport) {
		self.transport = transport
		transport.delegate = self
	}

	deinit {
		waitForOperations()
	}

	private var activeOperationCount: Int {
		var operationCount = 0
		for operation in operationQueue.operations where !operation.cancelled && !operation.finished {
			operationCount += 1
		}
		return operationCount
	}

	public func waitForOperations() {
		while activeOperationCount > 0 {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05))
		}
	}

	func enqueueOperation(operation: NSOperation) {
		operationQueue.addOperation(operation)
	}

	var operations: [NSOperation] {
		return operationQueue.operations
	}

	// TODO: consider removing
	public func enqueueBarrier(handler: () -> ()) {
		let blockOperation = NSBlockOperation(block: {
			NSOperationQueue.mainQueue().addOperationWithBlock(handler)
		})

		for operation in operationQueue.operations {
			blockOperation.addDependency(operation)
		}

		operationQueue.addOperation(blockOperation)
	}
	
	// MARK: - Device Transport Delegate

	func deviceTransportDidWriteData(transport: DeviceTransport) {
		wroteData()
	}

	func deviceTransportDidClose(transport: DeviceTransport) {
		// TODO: should we do anything else here?
	}

	func deviceTransportHandleData(transport: DeviceTransport, data: NSData) {
		handleData(data)
	}

	/* this is only for use by subclasses */
	func wroteData() {
		// no-op by default
	}

	func handleData(data: NSData) {
		fatalError("Subclasses must override")
	}
}
