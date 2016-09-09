//
//  EV3EnableToplineCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3EnableToplineCommand: EV3DirectCommand {
	private let enable: Bool

	public init(enable: Bool) {
		self.enable = enable
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.topline.rawValue)
		mutableData.appendUInt8(enable ? 1 : 0)

		return mutableData
	}
}
