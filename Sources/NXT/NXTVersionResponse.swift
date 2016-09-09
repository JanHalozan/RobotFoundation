//
//  NXTVersionResponse.swift
//  RobotFoundation
//
//  Copyright © 2016 Matt Rajca. All rights reserved.
//

import Foundation

public struct NXTVersionResponse: NXTResponse {
	public let status: NXTStatus

	public let minorProtocolVersion: UInt8
	public let majorProtocolVersion: UInt8
	public let minorFirmwareVersion: UInt8
	public let majorFirmwareVersion: UInt8

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.minorProtocolVersion = payloadData.readUInt8AtIndex(0)
		self.majorProtocolVersion = payloadData.readUInt8AtIndex(1)
		self.minorFirmwareVersion = payloadData.readUInt8AtIndex(2)
		self.majorFirmwareVersion = payloadData.readUInt8AtIndex(3)
	}
}
