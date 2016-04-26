//
//  DeviceEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

extension Device {
	public convenience init?(metaDevice: MetaDevice) {
		#if os(OSX)
		switch metaDevice.type {
		case .BluetoothDevice:
			self.init(transport: IOBluetoothDeviceTransport(address: metaDevice.uniqueIdentifier))
		case .HIDDevice:
			self.init(transport: HIDDeviceTransport(serialNumber: metaDevice.uniqueIdentifier))
		}
		#endif

		#if os(iOS)
		fatalError()
		#endif
	}
}
