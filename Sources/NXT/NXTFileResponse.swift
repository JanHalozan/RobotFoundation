//
//  NXTFileResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

struct NXTFileResponse: NXTResponse {
	let status: NXTStatus
	let handle: UInt8
	let filename: String
	let size: UInt32

	init?(data: NSData) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		self.handle = payloadData.readUInt8AtIndex(0)

		var name = [Int8](count: 20, repeatedValue: 0)
		data.getBytes(&name, range: NSMakeRange(1, 20))

		guard let filename = NSString(UTF8String: &name) else {
			return nil
		}

		self.filename = filename as String
		self.size = data.readUInt32AtIndex(21)
	}
}
