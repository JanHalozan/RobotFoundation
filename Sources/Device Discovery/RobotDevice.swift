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

	init(hidDevice: IOHIDDeviceRef) {
		type = .HIDDevice(hidDevice)
	}

	init(bluetoothDevice: IOBluetoothDevice) {
		type = .BluetoothDevice(bluetoothDevice)
	}
}
