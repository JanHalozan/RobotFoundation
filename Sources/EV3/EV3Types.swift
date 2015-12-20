//
//  EV3Types.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

enum EV3ReplyType: UInt8 {
	case Success = 0x2
	case Error = 0x4
}

enum EV3Port: UInt8 {
	case One = 0, Two, Three, Four
}
