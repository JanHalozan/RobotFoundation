//
//  LegacyUSBDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 6/29/16.
//

#if os(OSX)

import Foundation

final class LegacyUSBDeviceTransport: XPCBackedDeviceTransport {
	private let serialNumber: String

	init(serialNumber: String) {
		self.serialNumber = serialNumber
		super.init()
	}

	override var serviceName: String {
		return "com.Robotary.LegacyUSBTransportService"
	}

	override var identifier: String {
		return serialNumber
	}
}

#endif
