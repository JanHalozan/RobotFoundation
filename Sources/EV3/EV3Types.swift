//
//  EV3Types.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum EV3ReplyType: UInt8 {
	case success = 0x2
	case systemSuccess = 0x3
	case error = 0x4
	case systemError = 0x5

	var isError: Bool {
		return self == .error || self == .systemError
	}
}

public enum EV3SystemReturnStatus: UInt8 {
	case success = 0x0
	case endOfFile = 0x8
	case unknownError = 0x0A
}
