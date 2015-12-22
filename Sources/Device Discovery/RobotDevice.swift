//
//  RobotDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation
import IOKit.hid
import IOBluetooth

private enum RobotDeviceType {
	case HIDDevice(IOHIDDeviceRef)
	case BluetoothDevice(IOBluetoothDevice)
}

public class RobotDevice {
	private let type: RobotDeviceType

	public private(set) var name: String?

	init(hidDevice: IOHIDDeviceRef) {
		type = .HIDDevice(hidDevice)
		name = IOHIDDeviceGetProperty(hidDevice, kIOHIDProductKey)?.takeRetainedValue() as? String
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		type = .BluetoothDevice(bluetoothDevice)
	}
}
