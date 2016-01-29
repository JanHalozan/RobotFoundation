//
//  NXTWriteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTWriteCommand: NXTCommand {
	let handle: UInt8
	let contents: NSData // max size: 64 bytes

	var responseType: MindstormsResponse.Type {
		return NXTHandleSizeResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x83
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(handle)
		data.appendData(contents)
		return data.copy() as! NSData
	}
}
