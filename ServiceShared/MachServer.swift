//
//  MachServer.swift
//  RobotFoundation
//
//  Created by Matt on 9/11/16.
//

import Foundation

class MachServer : NSObject, NSMachPortDelegate, TransportClientProtocol {
	private let name: String
	private var transport: TransportServiceProtocol!
	private let requestQueue = DispatchQueue(label: "requests")
	private let connectionsQueue = DispatchQueue(label: "connections")

	private var connections = Set<Port>()

	// Created from the server thread.
	private var serverPort: Port?

	init(name: String, transportServiceType: TransportServiceProtocol.Type) {
		self.name = name
		super.init()
		transport = transportServiceType.init(delegate: self)

		NotificationCenter.default.addObserver(self, selector: #selector(portWasInvalidated), name: Port.didBecomeInvalidNotification, object: nil)
	}

	private func openConnection(port: Port) {
		connectionsQueue.async {
			self.connections.insert(port)
		}
	}

	func handle(_ message: PortMessage) {
		guard let data = message.components?.first as? Data else {
			assertionFailure()
			print("\(#function): invalid data")
			return
		}

		guard let plist = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(rawValue: 0), format: nil) else {
			assertionFailure()
			print("\(#function): invalid serialized data")
			return
		}

		guard let dict = plist as? [String: AnyObject] else {
			assertionFailure()
			print("\(#function): serialized data is not a dictionary")
			return
		}

		guard let type = dict[MachEventKey.type.rawValue] as? String else {
			assertionFailure()
			print("\(#function): dictionary doesn't contain a type")
			return
		}

		guard let parsedType = MachRequestType(rawValue: type) else {
			assertionFailure()
			print("\(#function): invalid type")
			return
		}

		switch parsedType {
		case .openConnection:
			openConnection(port: message.sendPort!)
		case .scheduleRead:
			guard let identifier = dict[MachEventKey.identifier.rawValue] as? NSString else {
				assertionFailure()
				print("\(#function): no identifier")
				return
			}

			requestQueue.async {
				self.transport.scheduleRead(identifier) { result in
					guard result == Int(kIOReturnSuccess) else {
						print("\(#function): an error occurred while scheduling a read: \(result)")
						return
					}
				}
			}
		case .writeData:
			guard let identifier = dict[MachEventKey.identifier.rawValue] as? NSString,
				  let data = dict[MachEventKey.data.rawValue] as? NSData,
				  let counter = dict[MachEventKey.counter.rawValue] as? Int else {
				assertionFailure()
				print("\(#function): missing parameters")
				return
			}

			requestQueue.async {
				self.transport.writeData(data, identifier: identifier) { result in
					let packet = [
						MachEventKey.type.rawValue: MachResponseType.receivedWriteResponse.rawValue as NSString,
						MachEventKey.result.rawValue: result as NSNumber,
						MachEventKey.counter.rawValue: counter as NSNumber
					]
					self.sendPacket(packet)
				}
			}
		}
	}

	private func sendPacket(_ packet: [String: AnyObject]) {
		guard let packetData = try? PropertyListSerialization.data(fromPropertyList: packet, format: .binary, options: 0) else {
			print("\(#function): could not serialize packet")
			assertionFailure()
			return
		}

		connectionsQueue.async {
			for connection in self.connections {
				let message = PortMessage(send: connection, receive: nil, components: [packetData])
				if !message.send(before: .distantFuture) {
					print("\(#function): the message could not be sent")
				}
			}
		}
	}

	func closedTransportConnection() {
		let packet = [
			MachEventKey.type.rawValue: MachResponseType.closedConnection.rawValue as NSString
		]
		sendPacket(packet)
	}

	func handleTransportData(_ data: NSData) {
		let packet = [
			MachEventKey.type.rawValue: MachResponseType.receivedData.rawValue as NSString,
			MachEventKey.data.rawValue: data as NSData
		]
		sendPacket(packet)
	}

	func run() {
		assert(Thread.isMainThread)
		Thread.detachNewThreadSelector(#selector(runThread), toTarget: self, with: nil)
	}

	@objc private func runThread() {
		assert(!Thread.isMainThread)
		assert(serverPort == nil)

		let port = NSMachPort()
		port.setDelegate(self)
		port.schedule(in: .current, forMode: .defaultRunLoopMode)
		serverPort = port

		RBMachBootstrapServer.register(port, withName: name)
		RunLoop.current.run()
	}

	@objc private func portWasInvalidated(note: NSNotification) {
		guard let port = note.object as? Port else {
			assertionFailure()
			return
		}

		assert(port !== serverPort)

		connectionsQueue.async {
			self.connections.remove(port)

			if self.connections.isEmpty {
				// Exit if no more connections...
				exit(0)
			}
		}
	}

	deinit {
		// This might not be a weak reference...
		serverPort?.setDelegate(nil)
		NotificationCenter.default.removeObserver(self)
	}
}
