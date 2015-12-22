//
//  RobotDeviceManager.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public protocol RobotDeviceManagerDelegate: class {
	func robotDeviceManagerDidFindDevice(device: RobotDevice)
}

public final class RobotDeviceManager: RobotDeviceSourceClient {
	private var sources = [RobotDeviceSource]()
	private let searchCriteria: [RobotDeviceDescriptor]
	private var foundDevices = [RobotDevice]()

	private weak var delegate: RobotDeviceManagerDelegate?

	public init(sourceTypes: [RobotDeviceSource.Type], searchCriteria: [RobotDeviceDescriptor], delegate: RobotDeviceManagerDelegate) {
		self.searchCriteria = searchCriteria
		self.delegate = delegate

		for sourceType in sourceTypes {
			let source = sourceType.init(client: self)
			self.sources.append(source)
		}
	}

	public func beginDiscovery() {
		for source in sources {
			source.beginDiscovery(searchCriteria)
		}
	}

	public func robotDeviceSourceDidFindDevice(device: RobotDevice) {
		foundDevices.append(device)
		delegate?.robotDeviceManagerDidFindDevice(device)
	}
}
