//
//  EV3Device.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class EV3Device: Device {
	public func enqueueCommand(command: EV3Command, responseHandler: EV3ResponseHandler) {
		enqueueCommands([command], responseHandler: responseHandler)
	}

	public func enqueueCommands(commands: [EV3Command], responseHandler: EV3ResponseHandler) {
		// TODO: system commands cannot be grouped
		let operation = EV3CommandGroupOperation(transport: transport, commands: commands, responseHandler: responseHandler)
		enqueueOperation(operation)
	}

	override func handleData(data: NSData) {
		for operation in operations {
			if let commandOperation = operation as? EV3CommandGroupOperation where commandOperation.canHandleResponseData(data) {
				commandOperation.handleResponseData(data)
			}
		}
	}
}
