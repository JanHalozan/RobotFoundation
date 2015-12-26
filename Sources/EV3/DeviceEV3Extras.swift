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
		switch metaDevice.internalType {
		case .BluetoothDevice(let bld):
			self.init(transport: IOBluetoothDeviceTransport(address: bld.addressString))
		case .HIDDevice(let hid):
			let serialNumber = IOHIDDeviceGetProperty(hid, kIOHIDSerialNumberKey)!.takeRetainedValue() as! String
			self.init(transport: HIDDeviceTransport(serialNumber: serialNumber))
		}
		#endif

		#if os(iOS)
		fatalError()
		#endif
	}
}
