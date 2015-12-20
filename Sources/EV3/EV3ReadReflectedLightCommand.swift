//
//  EV3ReadReflectedLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct EV3ReadReflectedLightCommand: EV3Command {
	let port: EV3Port

	var responseType: MindstormsResponse.Type {
		return EV3PercentFloatResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var numberOfGlobals: UInt8 {
		return 4 // 32-bit float
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		// Input device code
		mutableData.appendUInt8(0x99)

		// Ready SI
		mutableData.appendUInt8(29)

		// Layer 0
		mutableData.appendUInt8(0)

		mutableData.appendUInt8(port.rawValue)

		mutableData.appendUInt8(0)
		mutableData.appendUInt8(0)
		mutableData.appendUInt8(1)
		mutableData.appendUInt8(0x60) // write output to a global variable

		return mutableData.copy() as! NSData
	}
}
