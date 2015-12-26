//
//  HIDDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

#if os(OSX)

import Foundation
import IOKit.hid

class XPCBackedDeviceTransport: DeviceTransport {
	private var serviceConnection: NSXPCConnection?

	var serviceName: String {
		fatalError()
	}

	var identifier: String {
		fatalError()
	}

	override func open() throws {
		if serviceConnection == nil {
			serviceConnection = NSXPCConnection(serviceName: serviceName)
		}

		guard let serviceConnection = serviceConnection else {
			assertionFailure()
			return
		}

		serviceConnection.remoteObjectInterface = NSXPCInterface(withProtocol: XPCTransportServiceProtocol.self)
		serviceConnection.exportedObject = self
		serviceConnection.resume()

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			return
		}

		proxy.open(identifier) { result in
			dispatch_async(dispatch_get_main_queue()) {
				print(result)
				self.opened()
			}
		}
	}

	override func close() {
		guard let serviceConnection = serviceConnection else {
			return
		}

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			return
		}

		proxy.close { result in
			dispatch_async(dispatch_get_main_queue()) {
				print(result)
				self.closed()
			}
		}
	}

	override func writeData(data: NSData, handler: NSData -> ()) throws {
		guard let serviceConnection = serviceConnection else {
			return
		}

		guard let proxy = serviceConnection.remoteObjectProxy as? XPCTransportServiceProtocol else {
			assertionFailure()
			return
		}

		proxy.writeData(data) { data, result in
			dispatch_async(dispatch_get_main_queue()) {
				print(result)
				self.wroteData()

				if let data = data {
					handler(data)
				}
			}
		}
	}
}

#endif


