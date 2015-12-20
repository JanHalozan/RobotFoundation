//
//  EV3ReadLightCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3ReadLightType: UInt8 {
	case Reflected = 0
	case Ambient = 3
}

struct EV3ReadLightCommand: EV3Command {
	let port: EV3Port
	let lightType: EV3ReadLightType

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
		mutableData.appendUInt8(lightType.rawValue)
		mutableData.appendUInt8(1)
		mutableData.appendUInt8(0x60) // write output to a global variable

		return mutableData.copy() as! NSData
	}
}
