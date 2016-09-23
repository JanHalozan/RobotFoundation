//
//  RobotDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

#if os(OSX)
import IOKit.hid
import IOBluetooth
#endif

#if os(iOS)
import ExternalAccessory
#endif

public enum RobotDeviceType {
	#if os(OSX)
	case hidDevice
	case legacyUSBDevice
	case bluetoothDevice
	#endif

	#if os(iOS)
	case externalAccessory
	#endif
}

public enum DeviceClass: String {
	case NXT20 = "nxt20"
	case EV3 = "ev3"
	case Unknown = "unknown"
}

private let kDictionaryTypeKey = "type"
	private let kDictionaryTypeBluetooth = "bl"
	private let kDictionaryTypeHID = "hid"
	private let kDictionaryTypeLegacyUSB = "lusb"

private let kDictionaryClassKey = "class"
private let kDictionaryIdentifierKey = "identifier"
private let kDictionaryNameKey = "name"

public let MetaDeviceNameDidChangeNotificationName = "MetaDevice.notification.nameDidChange"

// A meta device can't be used to make connections. Rather, it describes a device's name, unique
// identifier, and other parameters and can be used to initialize concrete Devices (or subclasses thereof).
public final class MetaDevice {
	public let type: RobotDeviceType
	public var deviceClass: DeviceClass

	public private(set) var name: String
	public let uniqueIdentifier: String

	private(set) var userInfo = [String: Any]()

	init(type: RobotDeviceType, deviceClass: DeviceClass, uniqueIdentifier: String, name: String) {
		self.type = type
		self.name = name
		self.uniqueIdentifier = uniqueIdentifier
		self.deviceClass = deviceClass
	}

	public convenience init?(stringDictionary: [String: String]) {
		guard let type = stringDictionary[kDictionaryTypeKey] else {
			return nil
		}

	#if os(OSX)
		switch type {
		case kDictionaryTypeBluetooth:
			guard let identifier = stringDictionary[kDictionaryIdentifierKey] else {
				return nil
			}

			guard let name = stringDictionary[kDictionaryNameKey] else {
				return nil
			}

			guard let deviceClassString = stringDictionary[kDictionaryClassKey] else {
				return nil
			}

			guard let deviceClass = DeviceClass(rawValue: deviceClassString) else {
				return nil
			}

			self.init(type: .bluetoothDevice, deviceClass: deviceClass, uniqueIdentifier: identifier, name: name)
		case kDictionaryTypeHID:
			guard let identifier = stringDictionary[kDictionaryIdentifierKey] else {
				return nil
			}

			guard let name = stringDictionary[kDictionaryNameKey] else {
				return nil
			}

			self.init(type: .hidDevice, deviceClass: .EV3, uniqueIdentifier: identifier, name: name)
		case kDictionaryTypeLegacyUSB:
			guard let identifier = stringDictionary[kDictionaryIdentifierKey] else {
				return nil
			}

			guard let name = stringDictionary[kDictionaryNameKey] else {
				return nil
			}

			self.init(type: .legacyUSBDevice, deviceClass: .NXT20, uniqueIdentifier: identifier, name: name)
		default:
			fatalError("Unimplemented type")
			return nil
		}
	#else
		fatalError("Unimplemented")
	#endif
	}

	public var stringDictionary: [String: String] {
	#if os(OSX)
		switch type {
		case .bluetoothDevice:
			return [
				kDictionaryTypeKey: kDictionaryTypeBluetooth,
				kDictionaryIdentifierKey: uniqueIdentifier,
				kDictionaryNameKey: name,
				kDictionaryClassKey: deviceClass.rawValue
			]
		case .hidDevice:
			return [
				kDictionaryTypeKey: kDictionaryTypeHID,
				kDictionaryIdentifierKey: uniqueIdentifier,
				kDictionaryNameKey: name,
				kDictionaryClassKey: deviceClass.rawValue
			]
		case .legacyUSBDevice:
			return [
				kDictionaryTypeKey: kDictionaryTypeLegacyUSB,
				kDictionaryIdentifierKey: uniqueIdentifier,
				kDictionaryNameKey: name,
				kDictionaryClassKey: deviceClass.rawValue
			]
		}
	#else
		switch type {
		case .externalAccessory:
			fatalError("Unimplemented")
		}
	#endif
	}
	
	public func updateName(_ newName: String) {
		name = newName
		NotificationCenter.default.post(name: Notification.Name(rawValue: MetaDeviceNameDidChangeNotificationName), object: self)
	}
}

extension MetaDevice: Hashable {
	public var hashValue: Int {
		return uniqueIdentifier.hashValue
	}
}

public func ==(lhs: MetaDevice, rhs: MetaDevice) -> Bool {
	return lhs.uniqueIdentifier == rhs.uniqueIdentifier
}
