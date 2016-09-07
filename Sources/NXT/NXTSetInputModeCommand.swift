//
//  NXTSetInputModeCommand.swift
//  RobotFoundation
//
//  Created by Matt on 8/17/16.
//

import Foundation

public struct NXTSetInputModeCommand: NXTCommand {
	let port: NXTInputPort
	let sensorType: NXTSensorType
	let sensorMode: NXTSensorMode

	public init(port: NXTInputPort, sensorType: NXTSensorType, sensorMode: NXTSensorMode) {
		self.port = port
		self.sensorType = sensorType
		self.sensorMode = sensorMode
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x05
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		data.appendUInt8(sensorType.rawValue)
		data.appendUInt8(sensorMode.rawValue)
		return data.copy() as! NSData
	}
}

public struct NXTResetInputStateCommand: NXTCommand {
	let port: NXTInputPort

	public init(port: NXTInputPort) {
		self.port = port
	}

	public var responseType: MindstormsResponse.Type {
		return NXTGenericResponse.self
	}

	public var type: MindstormsCommandType {
		return .Direct
	}

	public var identifier: UInt8 {
		return 0x08
	}

	public var payloadData: NSData {
		let data = NSMutableData()
		data.appendUInt8(port.rawValue)
		return data.copy() as! NSData
	}
}
