//
//  EV3Constants.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

enum EV3OpCode: UInt8 {
	case UIRead = 0x81
	case InputDevice = 0x99
	case InputRead = 0x9A
	case InputReadSI = 0x9D
	case OutputSpeed = 0xA5
	case OutputStart = 0xA6
	case OutputStop = 0xA3
	case File = 0xC0
}

enum EV3FileOpSubcode: UInt8 {
	case OpenRead = 1
	case Close = 7
	case ReadBytes = 28
}

enum EV3InputDeviceOpSubcode: UInt8 {
	case GetRaw = 11
	case ReadyPct = 27
	case ReadyRaw = 28
	case ReadySI = 29
}

enum EV3UIReadOpSubcode: UInt8 {
	case GetOSVersion = 3
}

enum EV3SensorType: UInt8 {
	case KeepType = 0
	case Touch = 16
}

enum EV3InputPort: UInt8 {
	case One = 0, Two, Three, Four
}

struct EV3OutputPortOptions: OptionSetType {
	let rawValue: UInt8
	init(rawValue: UInt8) {
		self.rawValue = rawValue
	}

	static let A = EV3OutputPortOptions(rawValue: 1)
	static let B = EV3OutputPortOptions(rawValue: 2)
	static let C = EV3OutputPortOptions(rawValue: 4)
	static let D = EV3OutputPortOptions(rawValue: 8)
}

enum EV3Variables: UInt8 {
	case GlobalVar0 = 0x60
	case GlobalVar1 = 0x61
	case GlobalVar2 = 0x62
	case GlobalVar3 = 0x63
	case GlobalVar4 = 0x64
}

enum EV3Layer: UInt8 {
	case ThisBrick = 0
}

let EV3ColorMode = UInt8(2)
let EV3MaxFileLength = UInt16(64)
