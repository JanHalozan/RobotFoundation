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
		return .direct
	}

	var identifier: UInt8 {
		return 0x0A
	}

	var payloadData: Data {
		var data = Data()
		data.appendUInt8(port.rawValue)
		data.appendUInt8(relative ? 1 : 0)
		return data
	}
}
