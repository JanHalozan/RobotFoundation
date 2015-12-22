//
//  DeviceEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

extension Device {
	public convenience init?(metadevice: RobotDevice) {
		#if os(OSX)
		switch metadevice.internalType {
		case .BluetoothDevice(let bld):
			self.init(transport: IOBluetoothDeviceTransport(bluetoothDevice: bld))
		case .HIDDevice(let hid):
			self.init(transport: HIDDeviceTransport(device: hid))
		}
		#endif

		#if os(iOS)
		fatalError()
		#endif
	}
}
