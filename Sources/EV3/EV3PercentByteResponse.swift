//
//  EV3PercentByteResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct EV3PercentByteResponse: EV3Response {
	public let percent: UInt8?

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		let byte = data.readUInt8AtIndex(0)
		if byte <= 100 {
			percent = byte
		} else {
			percent = nil
		}

		responseLength = 1
	}
}
