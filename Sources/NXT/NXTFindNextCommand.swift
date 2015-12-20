//
//  NXTFindNextCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTFindNextCommand: NXTCommand {
	let handle: UInt8

	var responseType: MindstormsResponse.Type {
		return NXTFileResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x87
	}

	var payloadData: NSData {
		var handleLocal = handle
		return NSData(bytes: &handleLocal, length: sizeof(UInt8))
	}
}
