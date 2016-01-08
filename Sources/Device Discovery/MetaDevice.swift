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
