//
//  ExternalAccessoryTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

#if os(iOS)

import ExternalAccessory
import Foundation

final class ExternalAccessoryTransport: DeviceTransport {
	private let accessory: EAAccessory
	private let protocolString: String

	private var session: EASession?
	private var inputStream: NSInputStream?
	private var outputStream: NSOutputStream?

	init(accessory: EAAccessory, protocolString: String) {
		self.accessory = accessory
		self.protocolString = protocolString
	}

	override func open() throws {
		let session = EASession(accessory: accessory, forProtocol: protocolString)
		inputStream = session.inputStream
		outputStream = session.outputStream

		outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
		outputStream?.open()

		self.session = session
	}
}

#endif
