//
//  NXTStartProgramCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTStartProgramCommand: NXTCommand {
	let filename: String

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var identifier: UInt8 {
		return 0x0
	}

	var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
