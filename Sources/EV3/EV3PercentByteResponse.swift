//
//  EV3PercentByteResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3PercentByteResponse: EV3Response {
	public let percent: UInt8

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		percent = data.readUInt8AtIndex(0)
		responseLength = 1
	}
}
