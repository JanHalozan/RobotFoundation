//
//  EV3StartMotorCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/22/15.
//

import Foundation

public struct EV3StartMotorCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions

	public init(ports: EV3OutputPortOptions) {
		self.ports = ports
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputStart.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)

		return mutableData
	}
}
