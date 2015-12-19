//
//  EV3CommandOperation.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

final class EV3CommandOperation: NSOperation {
	private let transport: DeviceTransport
	private let command: EV3Command
	private let responseHandler: NXTResponseHandler?

	init(transport: DeviceTransport, command: EV3Command, responseHandler: NXTResponseHandler?) {
		self.transport = transport
		self.command = command
		self.responseHandler = responseHandler
		super.init()
	}

	override var concurrent: Bool {
		return true
	}

	override func start() {
		assert(NSThread.isMainThread())

		let prependTotalLength = transport is IOBluetoothDeviceTransport
		let data = command.formEV3PacketData(0, prependTotalLength: prependTotalLength)

		do {
			try transport.writeData(data)
		} catch {
			print("Cannot write packet data: \(error)")
		}
	}

	func handleResponseData(data: NSData) {
		
	}
}
