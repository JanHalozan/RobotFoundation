//
//  EV3Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class EV3Device: Device {
	public func enqueueCommand(command: EV3Command, isCritical: Bool = true, responseHandler: EV3ResponseHandler) {
		enqueueCommands([command], isCritical: isCritical, responseHandler: responseHandler)
	}

	public func enqueueCommands(commands: [EV3Command], isCritical: Bool = true, responseHandler: EV3ResponseHandler) {
		var encounteredSystemCommand = false
		for command in commands {
			guard command is EV3SystemCommand else {
				continue
			}

			if encounteredSystemCommand {
				// We have more than one! Oops!
				assertionFailure()
				return
			} else {
				encounteredSystemCommand = true
			}
		}

		let operation = EV3CommandGroupOperation(transport: transport, commands: commands, isCritical: isCritical, responseHandler: responseHandler)
		enqueueOperation(operation)
	}

	override func handleData(data: NSData) {
		let cachedOperations = operations
		for operation in cachedOperations {
			if let commandOperation = operation as? EV3CommandGroupOperation where commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
				return
			}
		}

		print("Unhandled EV3 response, operations: \(cachedOperations.count)")
	}
}
