//
//  NXTHandleSizeResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

public struct NXTHandleSizeResponse: NXTResponse {
	public let status: NXTStatus
	public let handle: UInt8
	public let size: UInt16

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)
		self.size = payloadData.readUInt16AtIndex(1)
	}
}
