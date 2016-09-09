//
//  Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

class DeviceOperation: Operation {
	fileprivate let isCritical: Bool

	init(isCritical: Bool) {
		self.isCritical = isCritical
		super.init()
	}
}

public class Device: DeviceTransportDelegate {
	let transport: DeviceTransport

	private lazy var operationQueue: OperationQueue = {
		let operationQueue = OperationQueue()
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
		for operation in operationQueue.operations where !operation.isCancelled && !operation.isFinished {
			operationCount += 1
		}
		return operationCount
	}

	private var criticalOperationCount: Int {
		var criticalOperationCount = 0
		for operation in operationQueue.operations where !operation.isCancelled && !operation.isFinished {
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
			RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05))
		}
	}

	public func waitForCriticalOperations() {
		while criticalOperationCount > 0 {
			RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05))
		}
	}

	func enqueueOperation(_ operation: DeviceOperation) {
		operationQueue.addOperation(operation)
	}

	var operations: [Operation] {
		return operationQueue.operations
	}

	// FIXME: consider removing
	public func enqueueBarrier(_ handler: @escaping () -> ()) {
		let blockOperation = BlockOperation(block: {
			OperationQueue.main.addOperation(handler)
		})

		for operation in operationQueue.operations {
			blockOperation.addDependency(operation)
		}

		operationQueue.addOperation(blockOperation)
	}
	
	// MARK: - Device Transport Delegate

	func deviceTransportDidWriteData(_ transport: DeviceTransport) {
		wroteData()
	}

	func deviceTransportDidClose(_ transport: DeviceTransport) {
		closedConnection()
	}

	func deviceTransportHandleData(_ transport: DeviceTransport, data: Data) {
		handleData(data)
	}

	/* this is only for use by subclasses */
	func wroteData() {
		// no-op by default
	}

	func handleData(_ data: Data) {
		fatalError("Subclasses must override")
	}

	func closedConnection() {
		// Don't cancel all operations here because the system may have simply disconnected from the device gracefully
		// and subsequent operations would have just re-connected.
	}
}
