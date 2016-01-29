//
//  NXTResetMotorPositionCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTResetMotorPositionCommand: NXTCommand {
	let port: NXTOutputPort
	let relative: Bool

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var identifier: UInt8 {
		return 0x0A
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		data.appendUInt8(relative ? 1 : 0)
		return data.copy() as! NSData
	}
}
