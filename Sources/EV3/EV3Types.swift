//
//  EV3Types.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3ReplyType: UInt8 {
	case Success = 0x2
	case SystemSuccess = 0x3
	case Error = 0x4
	case SystemError = 0x5
}
