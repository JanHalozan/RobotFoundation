//
//  NXTDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public final class NXTDevice: Device {
	public func enqueueCommand(command: NXTCommand, responseHandler: NXTCommandHandler) {
		if transport.openState.get() == .Closed {
			print("No open transport, won't bother enqueuing the command.")
			responseHandler(.Error(.TransportError(kIOReturnAborted)))
			return
		}

		let operation = NXTCommandOperation(transport: transport, command: command, responseHandler: responseHandler)
		enqueueOperation(operation)
	}

	override func handleData(data: NSData) {
		for operation in operations {
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
