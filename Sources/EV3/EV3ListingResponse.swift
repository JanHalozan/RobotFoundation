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

	public init?(data: NSData, userInfo: [String : Any]) {
		self.systemCommand = data.readUInt8AtIndex(0)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.UnknownError
		self.listSize = data.readUInt32AtIndex(2)
		self.handle = data.readUInt8AtIndex(6)

		// This is a system command so we can assume it's the only one.
		self.string = data.readStringAtIndex(7, length: data.length - 7)
		responseLength = data.length
	}
}

public struct EV3ContinueListingResponse: EV3Response {
	public let systemCommand: UInt8
	public let returnStatus: EV3SystemReturnStatus
	public let handle: UInt8

	public let string: String

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		self.systemCommand = data.readUInt8AtIndex(0)
		self.returnStatus = EV3SystemReturnStatus(rawValue: data.readUInt8AtIndex(1)) ?? EV3SystemReturnStatus.UnknownError
		self.handle = data.readUInt8AtIndex(2)

		// This is a system command so we can assume it's the only one.
		self.string = data.readStringAtIndex(3, length: data.length - 3)
		responseLength = data.length
	}
}
