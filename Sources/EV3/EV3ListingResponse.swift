//
//  EV3ListingResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public struct EV3ListingResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let listSize: UInt32
	public let handle: UInt8

	public let string: String

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		self.systemCommand = data.readUInt8AtIndex(0)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.unknownError
		self.listSize = data.readUInt32AtIndex(2)
		self.handle = data.readUInt8AtIndex(6)

		// This is a system command so we can assume it's the only one.
		self.string = data.readStringAtIndex(7, length: data.count - 7)
		responseLength = data.count
	}
}

public struct EV3ContinueListingResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let string: String

	public let responseLength: Int

	public init?(data: Data, userInfo: [String : Any]) {
		self.systemCommand = data.readUInt8AtIndex(0)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.unknownError
		self.handle = data.readUInt8AtIndex(2)

		// This is a system command so we can assume it's the only one.
		self.string = data.readStringAtIndex(3, length: data.count - 3)
		responseLength = data.count
	}
}
