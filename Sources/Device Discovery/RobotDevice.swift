//
//  RobotDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation
import IOKit.hid
import IOBluetooth

public enum RobotDeviceType {
	case HIDDevice, BluetoothDevice
}

enum RobotDeviceTypeInternal {
	case HIDDevice(IOHIDDeviceRef)
	case BluetoothDevice(IOBluetoothDevice)
}

public class RobotDevice {
	let internalType: RobotDeviceTypeInternal
	public let type: RobotDeviceType

	public private(set) var name: String?
	private(set) var uniqueIdentifier: String?

	init(hidDevice: IOHIDDeviceRef) {
		internalType = .HIDDevice(hidDevice)
		type = .HIDDevice
		name = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductKey)?.takeRetainedValue() as? String
		uniqueIdentifier = IOHIDDeviceGetProperty(hidDevice, kIOHIDSerialNumberKey)?.takeRetainedValue() as? String
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		internalType = .BluetoothDevice(bluetoothDevice)
		type = .BluetoothDevice
		name = bluetoothDevice.name
		uniqueIdentifier = bluetoothDevice.addressString
	}
}

extension RobotDevice: Hashable {
	public var hashValue: Int {
		return uniqueIdentifier?.hashValue ?? 1984
	}
}

public func ==(lhs: RobotDevice, rhs: RobotDevice) -> Bool {
	if let uq1 = lhs.uniqueIdentifier, uq2 = rhs.uniqueIdentifier where uq1 == uq2 {
		return true
	}

	return false
}
