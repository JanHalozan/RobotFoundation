//
//  NXTDeleteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTDeleteCommand: NXTCommand {
	let filename: String

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x85
	}

	var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
