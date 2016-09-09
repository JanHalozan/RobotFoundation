//
//  NXTSetOutputStateCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTSetOutputStateCommand: NXTCommand {
	let port: NXTOutputPort
	let power: Int8
	let outputMode: NXTOutputMode
	let regulationMode: NXTRegulationMode
	let turnRatio: Int8
	let runState: NXTRunState
	let tachoLimit: UInt32

	public init(port: NXTOutputPort, power: Int8, outputMode: NXTOutputMode, regulationMode: NXTRegulationMode, turnRatio: Int8, runState: NXTRunState, tachoLimit: UInt32) {
		self.port = port
		self.power = power
		self.outputMode = outputMode
		self.regulationMode = regulationMode
		self.turnRatio = turnRatio
		self.runState = runState
		self.tachoLimit = tachoLimit
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .direct
	}

	public var identifier: UInt8 {
		return 0x04
	}

	public var payloadData: Data {
		var data = Data()
		data.appendUInt8(port.rawValue)
		data.appendInt8(power)
		data.appendUInt8(outputMode.rawValue)
		data.appendUInt8(regulationMode.rawValue)
		data.appendInt8(turnRatio)
		data.appendUInt8(runState.rawValue)
		data.appendUInt32(tachoLimit)
		return data
	}
}
