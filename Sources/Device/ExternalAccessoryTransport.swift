//
//  ExternalAccessoryTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

#if os(iOS)

import ExternalAccessory
import Foundation

final class ExternalAccessoryTransport: DeviceTransport, ThreadedInputStreamDelegate {
	private enum TransportError: Error {
		case streamOpenError
	}

	private let accessory: EAAccessory

	private let session: EASession
	private var inputStream: ThreadedInputStream?
	private var outputStream: ThreadedOutputStream?

	init(accessory: EAAccessory, protocolString: String) {
		self.accessory = accessory
		session = EASession(accessory: accessory, forProtocol: protocolString)
	}

	private func openInputIfNecessary() throws {
		if inputStream?.streamStatus == .some(.open) {
			return
		}

		guard let inputStream = session.inputStream else {
			throw TransportError.streamOpenError
		}

		self.inputStream = ThreadedInputStream(stream: inputStream, delegate: self)
	}

	func threadedInputStreamDidClose() {
		handleClosedConnection()
	}

	func threadedInputStreamDidReceiveData(data: Data) {
		handleData(data)
	}

	private func openOutputIfNecessary() throws {
		if outputStream?.streamStatus == .some(.open) {
			return
		}

		guard let outputStream = session.outputStream else {
			throw TransportError.streamOpenError
		}

		self.outputStream = ThreadedOutputStream(stream: outputStream)
	}

	private func openIfNecessary() throws {
		try openInputIfNecessary()
		try openOutputIfNecessary()
	}

	override func writeData(_ data: Data, errorHandler: @escaping (Error) -> ()) throws {
		try openIfNecessary()

		outputStream?.writeData(data: data)
	}
}

#endif
