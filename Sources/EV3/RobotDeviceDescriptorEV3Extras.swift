//
//  RobotDeviceDescriptorEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//

import Foundation

extension RobotDeviceDescriptor {
	static func EV3() -> RobotDeviceDescriptor {
		return RobotDeviceDescriptor(productID: 0x5, vendorID: 0x0694, majorDeviceClass: 0, minorDeviceClass: 0)
	}
}
