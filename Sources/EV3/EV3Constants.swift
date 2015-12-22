//
//  EV3Constants.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

enum EV3OpCode: UInt8 {
	case InputDevice = 0x99
	case InputRead = 0x9A
}

enum EV3OpSubcode: UInt8 {
	case ReadyPct = 27
	case ReadyRaw = 28
	case ReadySI = 29
}

enum EV3SensorType: UInt8 {
	case KeepType = 0
	case Touch = 16
}

enum EV3Port: UInt8 {
	case One = 0, Two, Three, Four
}

enum EV3Variables: UInt8 {
	case GlobalVar0 = 0x60
}

enum EV3Layer: UInt8 {
	case ThisBrick = 0
}
