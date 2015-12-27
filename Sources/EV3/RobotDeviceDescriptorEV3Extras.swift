//
//  RobotDeviceDescriptorEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//

import Foundation

public extension RobotDeviceDescriptor {
	static func EV3() -> RobotDeviceDescriptor {
		return RobotDeviceDescriptor(productID: 0x5, vendorID: 0x694, majorDeviceClass: 0, minorDeviceClass: 0)
	}
}
