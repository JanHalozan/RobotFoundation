//
//  NXTPlaySoundFileCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTPlaySoundFileCommand: NXTCommand {
	let loop: Bool
	let filename: String

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var identifier: UInt8 {
		return 0x02
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(loop ? 1 : 0)
		data.appendNXTFilename(filename)
		return data.copy() as! NSData
	}
}
