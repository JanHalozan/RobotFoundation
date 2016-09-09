//
//  NXTWriteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTWriteCommand: NXTCommand {
	let handle: UInt8
	let contents: Data // max size: 64 bytes

	var responseType: MindstormsResponse.Type {
		return NXTHandleSizeResponse.self
	}

	var type: MindstormsCommandType {
		return .system
	}

	var identifier: UInt8 {
		return 0x83
	}

	var payloadData: Data {
		var data = Data()
		data.appendUInt8(handle)
		data.append(contents)
		return data
	}
}
