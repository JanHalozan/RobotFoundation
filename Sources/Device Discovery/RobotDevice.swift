//
//  RobotDevice.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation
import IOKit.hid
import IOBluetooth

public enum RobotDevice {
	case HIDDevice(IOHIDDeviceRef)
	case BluetoothDevice(IOBluetoothDevice)
}
