//
//  RobotDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

protocol RobotDeviceSourceClient: class {
	func robotDeviceSourceDidFindDevice(device: RobotDevice)
}

protocol RobotDeviceSource: class {
	init(client: RobotDeviceSourceClient)

	func beginDiscovery(searchCriteria: [RobotDeviceDescriptor])
}
