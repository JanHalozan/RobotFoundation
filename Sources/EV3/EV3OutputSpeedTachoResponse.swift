//
//  EV3OutputSpeedTachoResponse.swift
//  RobotFoundation
//
//  Created by Matt on 4/28/16.
//

import Foundation

public struct EV3OutputSpeedTachoResponse: EV3Response {
	public let speed: Int8
	public let tacho: UInt32

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		speed = data.readInt8AtIndex(0)
		tacho = data.readUInt32AtIndex(1)
		responseLength = 5
	}
}
