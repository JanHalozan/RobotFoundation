//
//  NXTReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTReadCommand: NXTCommand {
	let handle: UInt8
	let bytesToRead: UInt16 // max size: 64 bytes

	var responseType: MindstormsResponse.Type {
		return NXTDataResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x82
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(handle)
		data.appendUInt16(bytesToRead)
		return data.copy() as! NSData
	}
}
