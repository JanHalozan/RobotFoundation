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
	private var inputStream: InputStream?
	private var outputStream: OutputStream?

	init(accessory: EAAccessory, protocolString: String) {
		self.accessory = accessory
		self.protocolString = protocolString
	}

	func open() throws {
		let session = EASession(accessory: accessory, forProtocol: protocolString)
		inputStream = session.inputStream
		outputStream = session.outputStream

		outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.commonModes)
		outputStream?.open()

		self.session = session
	}
}

#endif
