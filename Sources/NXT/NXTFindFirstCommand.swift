//
//  NXTFindFirstCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTFindFirstCommand {
	let filename: String

	var response: NXTResponse.Type {
		return NXTFileResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x86
	}

	var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
