//
//  IOBluetoothDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

#if os(OSX)

import Foundation

/* supports RFCOMM communication */
final class IOBluetoothDeviceTransport: MachBackedDeviceTransport {
	private let address: String

	init(address: String) {
		self.address = address
		super.init()
	}

	override var serviceName: String {
		return "RJKYY38TY2.com.Robotary.Bluetooth"
	}

	override var executableName: String {
		return "BluetoothTransportService"
	}

	override var identifier: String {
		return address
	}
}

#endif
