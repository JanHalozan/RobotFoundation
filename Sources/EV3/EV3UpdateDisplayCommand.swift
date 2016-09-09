//
//  EV3UpdateDisplayCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3UpdateDisplayCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.update.rawValue)

		return mutableData
	}
}
