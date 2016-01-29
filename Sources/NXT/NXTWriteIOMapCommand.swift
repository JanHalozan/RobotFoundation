//
//  NXTWriteIOMapCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTWriteIOMapCommand: NXTCommand {
	let moduleID: UInt32
	let offset: UInt16
	let contents: NSData

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x95
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt32(moduleID)
		data.appendUInt16(offset)
		data.appendUInt16(UInt16(contents.length))
		data.appendData(contents)
		return data.copy() as! NSData
	}
}
