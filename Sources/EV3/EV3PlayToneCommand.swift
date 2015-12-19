//
//  EV3PlayToneCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct EV3PlayToneCommand: EV3Command {
	let frequency: UInt16
	let duration: UInt16 // ms

	var type: NXTCommandType {
		return .Direct
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()

		// Sound op code
		mutableData.appendUInt8(0x94)

		// Tone command
		mutableData.appendUInt8(0x1)

		// Sound level
		mutableData.appendLC1(0x2)

		mutableData.appendLC2(frequency)
		mutableData.appendLC2(duration)

		return mutableData.copy() as! NSData
	}
}
