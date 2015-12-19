//
//  NXTDeleteCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTDeleteCommand: NXTCommand {
	let filename: String

	var responseType: NXTResponse.Type {
		return NXTGenericResponse.self
	}

	var type: NXTCommandType {
		return .System
	}

	var identifier: UInt8 {
		return 0x85
	}

	var payloadData: NSData {
		return (filename as NSString).dataForFilename
	}
}
