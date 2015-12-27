//
//  NXTCloseCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTCloseCommand: NXTCommand {
	let handle: UInt8

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x84
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(handle)

		return mutableData.copy() as! NSData
	}
}
