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

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Topline.rawValue)
		mutableData.appendUInt8(enable ? 1 : 0)

		return mutableData.copy() as! NSData
	}
}
