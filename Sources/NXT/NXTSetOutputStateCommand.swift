//
//  NXTSetOutputStateCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

struct NXTSetOutputStateCommand: NXTCommand {
	let port: NXTOutputPort
	let power: Int8
	let outputMode: NXTOutputMode
	let regulationMode: NXTRegulationMode
	let turnRatio: Int8
	let runState: NXTRunState
	let tachoLimit: UInt32

	var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	var type: MindstormsCommandType {
		return .Direct
	}

	var identifier: UInt8 {
		return 0x04
	}

	var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		data.appendInt8(power)
		data.appendUInt8(outputMode.rawValue)
		data.appendUInt8(regulationMode.rawValue)
		data.appendInt8(turnRatio)
		data.appendUInt8(runState.rawValue)
		data.appendUInt32(tachoLimit)
		return data.copy() as! NSData
	}
}
