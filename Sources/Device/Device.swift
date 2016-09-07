//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

class DeviceOperation: NSOperation {
	private let isCritical: Bool

	init(isCritical: Bool) {
		self.isCritical = isCritical
		super.init()
	}
}

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
		waitForCriticalOperations()
	}

	private var activeOperationCount: Int {
		var operationCount = 0
		for operation in operationQueue.operations where !operation.cancelled && !operation.finished {
			operationCount += 1
		}
		return operationCount
	}

	private var criticalOperationCount: Int {
		var criticalOperationCount = 0
		for operation in operationQueue.operations where !operation.cancelled && !operation.finished {
			guard let deviceOperation = operation as? DeviceOperation else {
				continue
			}

			if deviceOperation.isCritical {
				criticalOperationCount += 1
			}
		}
		return criticalOperationCount
	}

	public func waitForOperations() {
		while activeOperationCount > 0 {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05))
		}
	}

	public func waitForCriticalOperations() {
		while criticalOperationCount > 0 {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05))
		}
	}

	func enqueueOperation(operation: DeviceOperation) {
		operationQueue.addOperation(operation)
	}

	var operations: [NSOperation] {
		return operationQueue.operations
	}

	// FIXME: consider removing
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
		closedConnection()
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

	func closedConnection() {
		// Don't cancel all operations here because the system may have simply disconnected from the device gracefully
		// and subsequent operations would have just re-connected.
	}
}
