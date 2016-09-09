//
//  RobotDeviceManager.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public protocol RobotDeviceManagerDelegate: class {
	func robotDeviceManagerDidFindDevice(_ device: MetaDevice)
	func robotDeviceManagerDidLoseDevice(_ device: MetaDevice)
}

public let RobotDeviceManagerDidFindDeviceNotificationName = "notification.DeviceDiscovery.RobotDeviceManager.DidFindDevice"
public let RobotDeviceManagerDidLoseDeviceNotificationName = "notification.DeviceDiscovery.RobotDeviceManager.DidLoseDevice"
	public let DeviceKey = "notification.key.device"

public final class RobotDeviceManager: RobotDeviceSourceClient {
	private var sources = [RobotDeviceSource]()
	private let searchCriteria: [RobotDeviceDescriptor]
	
	public private(set) var foundDevices = [MetaDevice]()

	private weak var delegate: RobotDeviceManagerDelegate?

	public init(sourceTypes: [RobotDeviceSource.Type], searchCriteria: [RobotDeviceDescriptor], delegate: RobotDeviceManagerDelegate?) {
		self.searchCriteria = searchCriteria
		self.delegate = delegate

		for sourceType in sourceTypes {
			let source = sourceType.init(client: self)
			sources.append(source)
		}
	}

	public func beginDiscovery() {
		for source in sources {
			source.beginDiscovery(searchCriteria: searchCriteria)
		}
	}

	public func robotDeviceSourceDidFindDevice(_ device: MetaDevice) {
		foundDevices.append(device)
		delegate?.robotDeviceManagerDidFindDevice(device)

		let userInfo = [DeviceKey: device] as [String: AnyObject]
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: RobotDeviceManagerDidFindDeviceNotificationName), object: self, userInfo: userInfo)
	}

	public func robotDeviceSourceDidLoseDevice(_ device: MetaDevice) {
		if let index = foundDevices.index(of: device) {
			foundDevices.remove(at: index)
		}
		delegate?.robotDeviceManagerDidLoseDevice(device)

		let userInfo = [DeviceKey: device] as [String: AnyObject]
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: RobotDeviceManagerDidLoseDeviceNotificationName), object: self, userInfo: userInfo)
	}
}
