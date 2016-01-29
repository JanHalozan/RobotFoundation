//
//  NXTOpenReadCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTOpenReadCommand: NXTCommand {
	let filename: String

	var responseType: MindstormsResponse.Type {
		return NXTHandleSizeResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x80
	}

	var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
