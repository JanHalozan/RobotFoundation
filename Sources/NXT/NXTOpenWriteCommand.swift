//
//  NXTOpenWriteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTOpenWriteCommand: NXTCommand {
	let filename: String
	let size: UInt32

	var responseType: MindstormsResponse.Type {
		return NXTHandleResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x81
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendNXTFilename(filename)
		data.appendUInt32(CFSwapInt32HostToLittle(size))
		return data.copy() as! NSData
	}
}
