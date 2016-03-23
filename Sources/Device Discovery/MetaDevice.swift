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
	case HIDDevice
	case BluetoothDevice(IOBluetoothDevice)
	#endif

	#if os(iOS)
	case ExternalAccessory
	#endif
}

enum RobotDeviceTypeInternal {
	#if os(OSX)
	case HIDDevice(IOHIDDeviceRef)
	case BluetoothDevice(IOBluetoothDevice)
	#endif

	#if os(iOS)
	case ExternalAccessory(EAAccessory)
	#endif
}

// A meta device can't be used to make connections. Rather, it describes a device's name, unique
// identifier, and other parameters and can be used to initialize concrete Devices (or subclasses thereof).
public final class MetaDevice {
	let internalType: RobotDeviceTypeInternal
	public let type: RobotDeviceType

	public private(set) var name: String?
	private(set) var uniqueIdentifier: String?

	private(set) var userInfo = [String: Any]()

	#if os(OSX)
	init(hidDevice: IOHIDDeviceRef) {
		internalType = .HIDDevice(hidDevice)
		type = .HIDDevice
		name = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductKey)?.takeUnretainedValue() as? String
		uniqueIdentifier = IOHIDDeviceGetProperty(hidDevice, kIOHIDSerialNumberKey)?.takeUnretainedValue() as? String
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		internalType = .BluetoothDevice(bluetoothDevice)
		type = .BluetoothDevice(bluetoothDevice)
		name = bluetoothDevice.name
		uniqueIdentifier = bluetoothDevice.addressString
	}
	#endif

	#if os(iOS)
	init(externalAccessory: EAAccessory) {
		type = .ExternalAccessory
		internalType = .ExternalAccessory(externalAccessory)
	}
	#endif

	public convenience init?(stringDictionary: [String: String]) {
		guard let type = stringDictionary["type"] else {
			return nil
		}

		switch type {
		case "bl":
			guard let address = stringDictionary["address"] else {
				return nil
			}

			let bluetoothDevice = IOBluetoothDevice(addressString: address)
			self.init(bluetoothDevice: bluetoothDevice)
		default:
			fatalError("Unimplemented")
			return nil
		}
	}

	public var stringDictionary: [String: String] {
		switch internalType {
		case .BluetoothDevice(let bluetoothDevice):
			return [
				"type": "bl",
				"address": bluetoothDevice.addressString
			]
		case .HIDDevice(let hidDevice):
			fatalError("Unimplemented")
			return [:]
		}
	}
}

extension MetaDevice: Hashable {
	public var hashValue: Int {
		return uniqueIdentifier?.hashValue ?? 1984
	}
}

public func ==(lhs: MetaDevice, rhs: MetaDevice) -> Bool {
	if let uq1 = lhs.uniqueIdentifier, uq2 = rhs.uniqueIdentifier where uq1 == uq2 {
		return true
	}

	return false
}

// MARK: - Device Class Retrieval

private let DeviceClassKey = "deviceClass"

public enum DeviceClass {
	case NXT20
	case EV3
	case Unknown
}

extension MetaDevice {
	private func deviceClassForBluetoothDevice(bluetoothDevice: IOBluetoothDevice) -> DeviceClass {
		userInfo.removeValueForKey(DeviceClassKey)
		bluetoothDevice.performSDPQuery(self)

		// TODO: avoid blocking
		while userInfo[DeviceClassKey] == nil {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}

		return userInfo[DeviceClassKey] as! DeviceClass
	}

	@objc private func sdpQueryComplete(device: IOBluetoothDevice!, status: IOReturn) {
		let services = device.services as! [IOBluetoothSDPServiceRecord]
		guard let firstService = services.first else {
			userInfo[DeviceClassKey] = DeviceClass.Unknown
			assertionFailure()
			return
		}

		guard let platform = firstService.attributes[258] as? IOBluetoothSDPDataElement else {
			// Hacky, but the NXTs don't have this key.
			userInfo[DeviceClassKey] = DeviceClass.NXT20
			return
		}

		guard platform.getStringValue().containsString("BlueZ") else {
			userInfo[DeviceClassKey] = DeviceClass.NXT20
			return
		}

		userInfo[DeviceClassKey] = DeviceClass.EV3
	}

	public var deviceClass: DeviceClass {
		switch internalType {
		case .BluetoothDevice(let bluetoothDevice):
			return deviceClassForBluetoothDevice(bluetoothDevice)
		case .HIDDevice(let hidDevice):
			fatalError()
		}
	}
}
