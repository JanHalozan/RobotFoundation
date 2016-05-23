//
//  NXTGenericResponse.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public struct NXTGenericResponse: NXTResponse {
	public let status: NXTStatus

	public init?(data: NSData, userInfo: [String : Any]) {
		guard let status = NXTStatus(responseData: data) else {
			return nil
		}

		self.status = status
	}
}
