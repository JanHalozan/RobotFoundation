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
		return .system
	}

	var identifier: UInt8 {
		return 0x81
	}

	var payloadData: Data {
		var data = Data()
		data.appendNXTFilename(filename)
		data.appendUInt32(CFSwapInt32HostToLittle(size))
		return data
	}
}
