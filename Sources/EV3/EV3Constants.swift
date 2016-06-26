//
//  EV3Constants.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

enum EV3OpCode: UInt8 {
	case UIRead = 0x81
	case UIWrite = 0x82
	case UIButton = 0x83
	case UIDraw = 0x84
	case Sound = 0x94
	case SoundTest = 0x95
	case SoundReady = 0x96
	case InputDevice = 0x99
	case InputRead = 0x9A
	case InputReadSI = 0x9D
	case OutputPower = 0xA4
	case OutputSpeed = 0xA5
	case OutputStart = 0xA6
	case OutputStop = 0xA3
	case OutputRead = 0xA8
	case OutputTest = 0xA9
	case OutputReady = 0xAA
	case OutputTimePower = 0xAD
	case OutputTimeSpeed = 0xAF
	case OutputTimeSync = 0xB1
	case File = 0xC0
	case MemoryUsage = 0xC5
	case COMGet = 0xD3
	case COMSet = 0xD4
}

enum EV3FileOpSubcode: UInt8 {
	case OpenRead = 1
	case Close = 7
	case ReadBytes = 28
	case WriteBytes = 29
}

enum EV3InputDeviceOpSubcode: UInt8 {
	case GetTypeMode = 5
	case GetRaw = 11
	case ReadyPct = 27
	case ReadyRaw = 28
	case ReadySI = 29
}

enum EV3SoundOpSubcode: UInt8 {
	case Break = 0
	case PlayTone = 1
	case Play = 2
}

enum EV3UIWriteOpSubcode: UInt8 {
	case LED = 27
}

enum EV3ButtonOpSubcode: UInt8 {
	case WaitForPress = 3
	case Pressed = 9
}

enum EV3UIDrawOpSubcode: UInt8 {
	case Update = 0
	case Clean = 1
	case Pixel = 2
	case Line = 3
	case Circle = 4
	case Text = 5
	case Icon = 6
	case FillRect = 9
	case Rect = 10
	case InverseRect = 16
	case SelectFont = 17
	case Topline = 18
	case FillWindow = 19
	case DotLine = 21
	case FillCircle = 24
	case Store = 25
	case Restore = 26
	case BMPFile = 28
}

enum EV3COMGetSubcode: UInt8 {
	case GetBrickName = 13
}

enum EV3COMSetSubcode: UInt8 {
	case SetBrickName = 8
}

enum EV3SensorType: UInt8 {
	case KeepType = 0
	case Touch = 16
}

public enum EV3ButtonConst: UInt8 {
	case Up = 1
	case Enter = 2
	case Down = 3
	case Right = 4
	case Left = 5
	case Back = 6
}

public enum EV3InputPort: UInt8 {
	case One = 0, Two, Three, Four
}

public struct EV3OutputPortOptions: OptionSetType {
	public let rawValue: UInt8
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}

	public static let A = EV3OutputPortOptions(rawValue: 1)
	public static let B = EV3OutputPortOptions(rawValue: 2)
	public static let C = EV3OutputPortOptions(rawValue: 4)
	public static let D = EV3OutputPortOptions(rawValue: 8)
}

enum EV3Layer: UInt8 {
	case ThisBrick = 0
}

public enum EV3StopType: UInt8 {
	case Coast = 0
	case Brake = 1
}

let EV3ColorMode = UInt8(2)
let EV3MaxFileLength = UInt16(64)

public let EV3TopLineHeight = UInt16(10)
public let EV3DisplayWidth = UInt16(178)
public let EV3DisplayHeight = UInt16(128)
