//
//  EV3OutputReadyCommand.swift
//  RobotFoundation
//
//  Created by Matt on 2/16/16.
//

import Foundation

public struct EV3OutputReadyCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions

	public init(ports: EV3OutputPortOptions) {
		self.ports = ports
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputReady.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)

		return mutableData
	}
}
