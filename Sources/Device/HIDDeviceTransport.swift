//
//  HIDDeviceTransport.swift
//  RobotFoundation
//
//  Created by Matt on 12/26/15.
//

#if os(OSX)

import Foundation

final class HIDDeviceTransport: XPCBackedDeviceTransport {
	private let serialNumber: String

	init(serialNumber: String) {
		self.serialNumber = serialNumber
		super.init()
	}

	override var serviceName: String {
		return "com.Xrobot.HIDTransportService"
	}

	override var identifier: String {
		return serialNumber
	}
}

#endif
