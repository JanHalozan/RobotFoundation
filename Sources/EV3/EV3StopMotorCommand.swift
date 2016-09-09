//
//  EV3StopMotorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3StopMotorCommand: EV3DirectCommand {
	public let port: EV3OutputPortOptions
	public let stopType: EV3StopType

	public init(port: EV3OutputPortOptions, stopType: EV3StopType) {
		self.port = port
		self.stopType = stopType
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputStop.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(port.rawValue)
		mutableData.appendUInt8(stopType.rawValue)

		return mutableData
	}
}
