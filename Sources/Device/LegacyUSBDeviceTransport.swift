//
//  LegacyUSBDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 6/29/16.
//

#if os(OSX)

import Foundation

final class LegacyUSBDeviceTransport: MachBackedDeviceTransport {
	private let serialNumber: String

	init(serialNumber: String) {
		self.serialNumber = serialNumber
		super.init()
	}

	override var serviceName: String {
		return "RJKYY38TY2.com.Robotary.Legacy"
	}

	override var executableName: String {
		return "LegacyUSBTransportService"
	}

	override var identifier: String {
		return serialNumber
	}
}

#endif
