//
//  EV3SensorTypeModeResponse.swift
//  RobotFoundation
//
//  Created by Matt on 6/26/16.
//

import Foundation

public struct EV3SensorTypeModeResponse: EV3Response {
	public let type: UInt8
	public let mode: UInt8

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String: Any]) {
		type = data.readUInt8AtIndex(0)
		mode = data.readUInt8AtIndex(1)
		responseLength = 2
	}
}
