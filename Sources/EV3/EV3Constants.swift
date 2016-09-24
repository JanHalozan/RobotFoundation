//
//  EV3Constants.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation

enum EV3OpCode: UInt8 {
	case uiRead = 0x81
	case uiWrite = 0x82
	case uiButton = 0x83
	case uiDraw = 0x84
	case sound = 0x94
	case soundTest = 0x95
	case soundReady = 0x96
	case inputDevice = 0x99
	case inputRead = 0x9A
	case inputReadSI = 0x9D
	case outputPower = 0xA4
	case outputSpeed = 0xA5
	case outputStart = 0xA6
	case outputStop = 0xA3
	case outputRead = 0xA8
	case outputTest = 0xA9
	case outputReady = 0xAA
	case outputTimePower = 0xAD
	case outputTimeSpeed = 0xAF
	case outputStepSync = 0xB0
	case outputTimeSync = 0xB1
	case file = 0xC0
	case memoryUsage = 0xC5
	case comGet = 0xD3
	case comSet = 0xD4
}

enum EV3FileOpSubcode: UInt8 {
	case openRead = 1
	case close = 7
	case readBytes = 28
	case writeBytes = 29
}

enum EV3InputDeviceOpSubcode: UInt8 {
	case getTypeMode = 5
	case getRaw = 11
	case getName = 21
}

enum EV3SoundOpSubcode: UInt8 {
	case `break` = 0
	case playTone = 1
	case play = 2
}

enum EV3UIWriteOpSubcode: UInt8 {
	case screenBlock = 16
	case initRun = 25
	case led = 27
}

enum EV3ButtonOpSubcode: UInt8 {
	case waitForPress = 3
	case pressed = 9
}

enum EV3UIDrawOpSubcode: UInt8 {
	case update = 0
	case clean = 1
	case pixel = 2
	case line = 3
	case circle = 4
	case text = 5
	case icon = 6
	case fillRect = 9
	case rect = 10
	case inverseRect = 16
	case selectFont = 17
	case topline = 18
	case fillWindow = 19
	case dotLine = 21
	case fillCircle = 24
	case store = 25
	case restore = 26
	case bmpFile = 28
}

enum EV3COMGetSubcode: UInt8 {
	case getBrickName = 13
}

enum EV3COMSetSubcode: UInt8 {
	case setBrickName = 8
}

public enum EV3SensorType: UInt8 {
	case keepType = 0
	case touch = 16
	case light = 29
	case ultrasound = 30
	case gyro = 32
	case ir = 33
}

public enum EV3ButtonConst: UInt8 {
	case up = 1
	case enter = 2
	case down = 3
	case right = 4
	case left = 5
	case back = 6
}

public enum EV3RawInputPort: UInt8 {
	case one = 0, two, three, four
}

public enum EV3OutputPort: UInt8 {
	case a = 0, b, c, d
}

public struct EV3OutputPortOptions: OptionSet {
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
	case thisBrick = 0
}

public enum EV3StopType: UInt8 {
	case coast = 0
	case brake = 1
}

let EV3ColorMode = UInt8(2)
let EV3MaxFileLength = UInt16(64)

public let EV3TopLineHeight = UInt16(10)
public let EV3DisplayWidth = UInt16(178)
public let EV3DisplayHeight = UInt16(128)
