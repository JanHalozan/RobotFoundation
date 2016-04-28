//
//  NXTDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTDataResponse: NXTResponse {
	public let status: NXTStatus
	public let handle: UInt8
	public let size: UInt16
	public let contents: NSData

	public init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)
		self.size = payloadData.readUInt16AtIndex(1)
		self.contents = payloadData.subdataWithRange(NSMakeRange(3, payloadData.length - 3))
	}
}
