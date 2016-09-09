//
//  NXTTypes.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum NXTInputPort: UInt8 {
	case one = 0, two, three, four
}

public enum NXTSensorType: UInt8 {
	case noSensor = 0x0
	case `switch`
	case temperature
	case reflection
	case angle
	case lightActive
	case lightInactive
	case sounddB
	case sounddBA
	case custom
	case lowSpeed
	case lowSpeed9V
	case hiSpeed
	case colorFull
	case colorRed
	case colorGreen
	case colorBlue
	case colorNone
	case colorExit
}

public enum NXTSensorMode: UInt8 {
	case raw = 0x0
	case boolean = 0x20
	case transitionCounter = 0x40
	case periodicCounter = 0x60
	case percentFull = 0x80
	case celsius = 0xA0
	case fahrenheit = 0xC0
	case angleSteps = 0xE0
}

public enum NXTOutputPort: UInt8 {
	case a = 0, b, c
	case all = 0xFF
}

public struct NXTOutputMode: OptionSet {
	public let rawValue: UInt8
	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}

	public static let MotorOn = NXTOutputMode(rawValue: 1)
	public static let Brake = NXTOutputMode(rawValue: 2)
	public static let Regulated = NXTOutputMode(rawValue: 4)
}

public enum NXTRegulationMode: UInt8 {
	case idle = 0x0
	case motorSpeed = 0x01
	case motorSync = 0x02
}

public enum NXTRunState: UInt8 {
	case idle = 0x0
	case rampUp = 0x10
	case running = 0x20
	case rampDown = 0x40
}

public enum NXTStatus: UInt8 {
	case statusSuccess = 0x0
	case noMoreHandles = 0x81
	case noSpace = 0x82
	case noMoreFiles = 0x83
	case endOfFileExpected = 0x84
	case endOfFile = 0x85
	case notALinearFile = 0x86
	case fileNotFound = 0x87
	case handleAllReadyClosed = 0x88
	case noLinearSpace = 0x89
	case undefinedError = 0x8A
	case fileIsBusy = 0x8B
	case noWriteBuffers = 0x8C
	case appendNotPossible = 0x8D
	case fileIsFull = 0x8E
	case fileExists = 0x8F
	case moduleNotFound = 0x90
	case outOfBoundary = 0x91
	case illegalFileName = 0x92
	case illegalHandle = 0x93
}
