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

	public init?(data: Data, userInfo: [String : Any]) {
		guard let (_, status) = processReplyWithResponseData(data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)

		var name = [UInt8](repeating: 0, count: 20)
		payloadData.copyBytes(to: &name, from: 1..<21)

		guard let filename = (name.withUnsafeBufferPointer { ptr in
			return String(validatingUTF8: unsafeBitCast(ptr.baseAddress!, to: UnsafePointer<Int8>.self))
		}) else {
			return nil
		}

		self.filename = filename
		self.size = payloadData.readUInt32AtIndex(21)
	}
}
