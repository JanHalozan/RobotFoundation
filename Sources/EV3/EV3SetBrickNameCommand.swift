//
//  EV3SetBrickNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/28/16.
//

import Foundation

public struct EV3SetBrickNameCommand: EV3DirectCommand {
	public let name: String

	public init(name: String) {
		self.name = name
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.comSet.rawValue)
		mutableData.appendUInt8(EV3COMSetSubcode.setBrickName.rawValue)
		mutableData.appendLCS(name)

		return mutableData
	}
}
