//
//  EV3StorageResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/27/15.
//

import Foundation

public struct EV3StorageResponse: EV3Response {
	public let totalSize: UInt32
	public let freeSize: UInt32

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		totalSize = data.readUInt32AtIndex(0)
		freeSize = data.readUInt32AtIndex(4)
		responseLength = 8
	}
}
