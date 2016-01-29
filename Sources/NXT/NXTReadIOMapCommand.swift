//
//  NXTReadIOMapCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

struct NXTReadIOMapCommand: NXTCommand {
	let module: UInt32
	let offset: UInt16
	let bytesToRead: UInt16 // max seems to be 64 bytes

	var responseType: MindstormsResponse.Type {
		return NXTIOMapResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x94
	}

	var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt32(module)
		mutableData.appendUInt16(offset)
		mutableData.appendUInt16(bytesToRead)
		return mutableData.copy() as! NSData
	}
}

