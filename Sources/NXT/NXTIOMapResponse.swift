//
//  NXTIOMapResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/28/16.
//

import Foundation

public struct NXTIOMapResponse: NXTResponse {
	public let status: NXTStatus
	public let module: UInt32
	public let bytesRead: UInt16
	public let contents: NSData

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.module = payloadData.readUInt32AtIndex(0)
		self.bytesRead = payloadData.readUInt16AtIndex(4)
		self.contents = payloadData.subdataWithRange(NSMakeRange(6, Int(bytesRead)))
	}
}
