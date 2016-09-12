//
//  MachBackedDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 9/11/16.
//

#if os(OSX)

import Foundation
import IOKit.hid

private final class MachDelegate: NSObject, NSMachPortDelegate {
	let handler: (PortMessage) -> ()

	init(handler: @escaping (PortMessage) -> ()) {
		self.handler = handler
	}

	func handle(_ message: PortMessage) {
		handler(message)
	}
}

typealias ErrorHandler = (Error) -> ()

class MachBackedDeviceTransport: DeviceTransport, TransportClientProtocol {
	// Services can talk back to us on this port.
	private let clientPort: NSMachPort
	private let serverQueue = DispatchQueue(label: "server")
	private lazy var machDelegate: MachDelegate = { [unowned self] in
		return MachDelegate(handler: self.handleMessage)
	}()
	private static var errorCounter = 0
	private var errorHandlers = [Int: ErrorHandler]()
	private let errorsQueue = DispatchQueue(label: "error handlers")

	private var serverConnection: NSMachPort?

	override init() {
		clientPort = NSMachPort()
		super.init()

		// We need to ensure we schedule this on the main queue.
		assert(Thread.isMainThread)
		clientPort.setDelegate(self.machDelegate)
		clientPort.schedule(in: .current, forMode: .commonModes)

		NotificationCenter.default.addObserver(self, selector: #selector(portBecameInvalid), name: Port.didBecomeInvalidNotification, object: nil)
	}

	deinit {
		// This may not be a weak reference...
		clientPort.setDelegate(nil)
		NotificationCenter.default.removeObserver(self)
	}

	@objc private func portBecameInvalid(note: Notification) {
		assert(Thread.isMainThread)

		guard let port = note.object as? Port else {
			assertionFailure()
			return
		}

		assert(port !== clientPort)

		serverQueue.async {
			if port === self.serverConnection {
				self.serverConnection = nil
			}
		}
	}

	var serviceName: String {
		fatalError("Subclasses must override this method")
	}

	var executableName: String {
		fatalError("Subclasses must override this method")
	}

	var identifier: String {
		fatalError("Subclasses must override this method")
	}

	func handleMessage(_ message: PortMessage) {
		assert(Thread.isMainThread)

		guard let data = message.components?.first as? Data else {
			assertionFailure()
			print("\(#function): no data to read")
			return
		}

		guard let plist = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(rawValue: 0), format: nil) else {
			assertionFailure()
			print("\(#function): could not de-serialize the request")
			return
		}

		guard let request = plist as? [String: AnyObject] else {
			assertionFailure()
			print("\(#function): unexpected format")
			return
		}

		guard let type = request[MachEventKey.type.rawValue] as? String else {
			assertionFailure()
			print("\(#function): no request type")
			return
		}

		guard let parsedType = MachResponseType(rawValue: type) else {
			assertionFailure()
			print("\(#function): unknown type")
			return
		}

		switch parsedType {
		case .receivedData:
			guard let packetData = request[MachEventKey.data.rawValue] as? NSData else {
				assertionFailure()
				print("\(#function): no packet data")
				return
			}

			handleTransportData(packetData)
		case .receivedWriteResponse:
			guard let result = request[MachEventKey.result.rawValue] as? Int,
				  let counter = request[MachEventKey.counter.rawValue] as? Int else {
				assertionFailure()
				print("\(#function): missing values")
				return
			}

			guard result == Int(kIOReturnSuccess) else {
				errorsQueue.async {
					if let handler = self.errorHandlers.removeValue(forKey: counter) {
						handler(IOReturn(result))
					}
				}
				return
			}

			wroteData()
		case .closedConnection:
			handleClosedConnection()
		}
	}

	private func openConnectionIfNecessary() {
		var needsToConnect = false
		serverQueue.sync {
			needsToConnect = serverConnection == nil
			assert(serverConnection?.isValid ?? true)
		}

		guard needsToConnect else {
			return
		}

		if RBMachBootstrapServer.port(withName: serviceName) == nil {
			// Launch the service first.
			let task = Process()
			let frameworksURL = Bundle.main.privateFrameworksURL!
			let robotFoundationURL = frameworksURL.appendingPathComponent("RobotFoundation.framework/Versions/A", isDirectory: true)
			let executable = robotFoundationURL.appendingPathComponent(self.executableName, isDirectory: false)
			task.launchPath = executable.path
			task.launch()

			// Wait for the port to become available.
			// This is usually called on a background thread so blocking for a bit is okay.
			while RBMachBootstrapServer.port(withName: serviceName) == nil {
				Thread.sleep(forTimeInterval: 0.1)
			}
		}

		guard let port = RBMachBootstrapServer.port(withName: serviceName) else {
			assertionFailure()
			return
		}

		serverQueue.sync {
			self.serverConnection = port
		}

		let packet = [
			MachEventKey.type.rawValue: MachRequestType.openConnection.rawValue as NSString
		]
		sendPacket(packet)
	}

	private func sendPacket(_ packet: [String: AnyObject]) {
		openConnectionIfNecessary()

		guard let packetData = try? PropertyListSerialization.data(fromPropertyList: packet, format: .binary, options: 0) else {
			print("\(#function): could not serialize packet")
			assertionFailure()
			return
		}

		serverQueue.async {
			assert(self.serverConnection != nil)
			let message = PortMessage(send: self.serverConnection, receive: self.clientPort, components: [packetData])
			if !message.send(before: .distantFuture) {
				print("\(#function): the message could not be sent")
			}
		}
	}

	override func writeData(_ data: Data, errorHandler: @escaping ErrorHandler) throws {
		var counter = 0
		errorsQueue.sync {
			MachBackedDeviceTransport.errorCounter += 1
			counter = MachBackedDeviceTransport.errorCounter
			errorHandlers[counter] = errorHandler
		}

		let packet = [
			MachEventKey.type.rawValue: MachRequestType.writeData.rawValue as NSString,
			MachEventKey.data.rawValue: data as NSData,
			MachEventKey.identifier.rawValue: identifier as NSString,
			MachEventKey.counter.rawValue: counter as NSNumber
		]
		sendPacket(packet)
	}

	override func scheduleRead() {
		let packet = [
			MachEventKey.type.rawValue: MachRequestType.scheduleRead.rawValue as NSString,
			MachEventKey.identifier.rawValue: identifier as NSString
		]
		sendPacket(packet)
	}

	@objc func handleTransportData(_ data: NSData) {
		self.handleData(data as Data)
	}
	
	@objc func closedTransportConnection() {
		self.handleClosedConnection()
	}
}

#endif
