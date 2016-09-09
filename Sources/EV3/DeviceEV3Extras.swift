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
		case .bluetoothDevice:
			self.init(transport: IOBluetoothDeviceTransport(address: metaDevice.uniqueIdentifier))
		case .hidDevice:
			switch metaDevice.deviceClass {
			case .EV3:
				self.init(transport: HIDDeviceTransport(serialNumber: metaDevice.uniqueIdentifier))
			case .NXT20:
				self.init(transport: LegacyUSBDeviceTransport(serialNumber: metaDevice.uniqueIdentifier))
			case .Unknown:
				return nil
			}
		case .legacyUSBDevice:
			switch metaDevice.deviceClass {
			case .NXT20:
				self.init(transport: LegacyUSBDeviceTransport(serialNumber: metaDevice.uniqueIdentifier))
			case .EV3:
				fallthrough
			case .Unknown:
				return nil
			}
		}
		#endif

		#if os(iOS)
		fatalError()
		#endif
	}
}
