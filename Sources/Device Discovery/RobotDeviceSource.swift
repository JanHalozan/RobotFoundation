//
//  RobotDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public protocol RobotDeviceSourceClient: class {
	func robotDeviceSourceDidFindDevice(device: RobotDevice)
}

public protocol RobotDeviceSource: class {
	init(client: RobotDeviceSourceClient)

	func beginDiscovery(searchCriteria: [RobotDeviceDescriptor])
}
