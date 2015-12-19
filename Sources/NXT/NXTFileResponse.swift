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

		var handle = UInt8()
		payloadData.getBytes(&handle, range: NSMakeRange(0, 1))

		self.handle = handle

		var name = [Int8](count: 20, repeatedValue: 0)
		data.getBytes(&name, range: NSMakeRange(1, 20))

		guard let filename = NSString(UTF8String: &name) else {
			return nil
		}

		self.filename = filename as String

		var size = UInt32()
		data.getBytes(&size, range: NSMakeRange(21, 4))

		self.size = NSSwapLittleIntToHost(size)
	}
}
