//
//  EV3TestOutputCommand.swift
//  RobotFoundation
//
//  Created by Matt on 2/13/16.
//

import Foundation

public struct EV3TestOutputCommand: EV3DirectCommand {
	public let ports: EV3OutputPortOptions

	public init(ports: EV3OutputPortOptions) {
		self.ports = ports
	}

	public var responseType: MindstormsResponse.Type {
		return EV3BooleanResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return 1
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.outputTest.rawValue)
		mutableData.appendUInt8(EV3Layer.thisBrick.rawValue)
		mutableData.appendUInt8(ports.rawValue)
		mutableData.appendGV2(offset)

		return mutableData
	}
}
