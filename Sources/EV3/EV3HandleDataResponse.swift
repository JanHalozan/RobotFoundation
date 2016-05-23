//
//  EV3HandleDataResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/25/15.
//

import Foundation

public struct EV3HandleDataResponse: EV3Response {
	public let handle: UInt32
	public let data: NSData

	public let responseLength: Int

	public init?(data: NSData, userInfo: [String : Any]) {
		self.handle = data.readUInt32AtIndex(0)

		//let toEnd = Int(length) - 7 // size (2 bytes) not included
		//self.data = data.subdataWithRange(NSMakeRange(4, toEnd))
		self.data = NSData()

		responseLength = 0
		// TOOD: This is broken but that will not matter if #243 is fixed 
	}
}
