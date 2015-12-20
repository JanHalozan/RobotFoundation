//
//  HIDDeviceManagerEV3Extras.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//

#if os(OSX)

import Foundation

extension HIDDeviceManager {
	func searchForEV3Devices() throws {
		try searchForDeviceWithProductID(0x5, vendorID: 0x0694)
	}
}

#endif
