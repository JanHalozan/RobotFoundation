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

public let RobotDeviceManagerDidFindDeviceNotificationName = "notification.DeviceDiscovery.RobotDeviceManager.DidFindDevice"
public let RobotDeviceManagerDidLoseDeviceNotificationName = "notification.DeviceDiscovery.RobotDeviceManager.DidLoseDevice"
	public let DeviceKey = "notification.key.device"

public final class RobotDeviceManager: RobotDeviceSourceClient {
	private var sources = [RobotDeviceSource]()
	private let searchCriteria: [RobotDeviceDescriptor]
	
	public private(set) var foundDevices = [RobotDevice]()

	private weak var delegate: RobotDeviceManagerDelegate?

	public init(sourceTypes: [RobotDeviceSource.Type], searchCriteria: [RobotDeviceDescriptor], delegate: RobotDeviceManagerDelegate?) {
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

		let userInfo = [DeviceKey: device] as [String: AnyObject]
		NSNotificationCenter.defaultCenter().postNotificationName(RobotDeviceManagerDidFindDeviceNotificationName, object: self, userInfo: userInfo)
	}

	public func robotDeviceSourceDidLoseDevice(device: RobotDevice) {
		if let index = foundDevices.indexOf(device) {
			foundDevices.removeAtIndex(index)
		}

		let userInfo = [DeviceKey: device] as [String: AnyObject]
		NSNotificationCenter.defaultCenter().postNotificationName(RobotDeviceManagerDidLoseDeviceNotificationName, object: self, userInfo: userInfo)
	}
}
