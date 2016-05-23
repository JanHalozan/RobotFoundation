//
//  NXTDeviceInfoResponse.swift
//  RobotFoundation
//
//  Created by Matt on 1/29/16.
//

import Foundation

public struct NXTDeviceInfoResponse: NXTResponse {
	public let status: NXTStatus

	public let brickName: String
	public let freeSpace: UInt32 // bytes

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status

		guard let payloadData = data.payloadData else {
			return nil
		}

		let nameData = payloadData.subdataWithRange(NSMakeRange(0, 15))
		brickName = NSString(data: nameData, encoding: NSUTF8StringEncoding)! as String

		self.freeSpace = payloadData.readUInt32AtIndex(26)
	}
}
