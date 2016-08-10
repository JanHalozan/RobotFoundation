//
//  NXTFileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct NXTFileResponse: NXTResponse {
	public let status: NXTStatus
	public let handle: UInt8
	public let filename: String
	public let size: UInt32

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)

		var name = [Int8](count: 20, repeatedValue: 0)
		payloadData.getBytes(&name, range: NSMakeRange(1, 20))

		guard let filename = NSString(UTF8String: &name) else {
			return nil
		}

		self.filename = filename as String
		self.size = payloadData.readUInt32AtIndex(21)
	}
}
