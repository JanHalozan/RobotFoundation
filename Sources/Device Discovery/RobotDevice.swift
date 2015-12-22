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

private enum RobotDeviceTypeInternal {
	case HIDDevice(IOHIDDeviceRef)
	case BluetoothDevice(IOBluetoothDevice)
}

public class RobotDevice {
	private let internalType: RobotDeviceTypeInternal
	public let type: RobotDeviceType

	public private(set) var name: String?

	init(hidDevice: IOHIDDeviceRef) {
		internalType = .HIDDevice(hidDevice)
		type = .HIDDevice
		name = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductKey)?.takeRetainedValue() as? String
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		internalType = .BluetoothDevice(bluetoothDevice)
		type = .BluetoothDevice
		name = bluetoothDevice.name
	}
}
