//
//  NXTDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class NXTDevice: Device {
	// The device will wait until all critical commands complete before going away.
	public func enqueueCommand(_ command: NXTCommand, isCritical: Bool = true, responseHandler: @escaping NXTCommandHandler) {
		let operation = NXTCommandOperation(transport: transport, command: command, isCritical: isCritical, responseHandler: responseHandler)
		enqueueOperation(operation)
	}

	override func handleData(_ data: Data) {
		let cachedOperations = operations
		for operation in cachedOperations {
			if let commandOperation = operation as? NXTCommandOperation, commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
				return
			}
		}

	#if DEBUG
		print("Unhandled NXT response, operations: \(cachedOperations.count)")
	#endif
	}
}
