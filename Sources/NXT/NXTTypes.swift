//
//  NXTTypes.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public enum NXTOutputPort: UInt8 {
	case A = 0, B, C
	case All = 0xFF
}

public enum NXTOutputMode: UInt8 {
	case MotorOn = 0x01
	case Brake = 0x02
	case Regulated = 0x04
}

public enum NXTRegulationMode: UInt8 {
	case Idle = 0x0
	case MotorSpeed = 0x01
	case MotorSync = 0x02
}

public enum NXTRunState: UInt8 {
	case Idle = 0x0
	case RampUp = 0x10
	case Running = 0x20
	case RampDown = 0x40
}

public enum NXTStatus: UInt8 {
	case StatusSuccess = 0x0
	case NoMoreHandles = 0x81
	case NoSpace = 0x82
	case NoMoreFiles = 0x83
	case EndOfFileExpected = 0x84
	case EndOfFile = 0x85
	case NotALinearFile = 0x86
	case FileNotFound = 0x87
	case HandleAllReadyClosed = 0x88
	case NoLinearSpace = 0x89
	case UndefinedError = 0x8A
	case FileIsBusy = 0x8B
	case NoWriteBuffers = 0x8C
	case AppendNotPossible = 0x8D
	case FileIsFull = 0x8E
	case FileExists = 0x8F
	case ModuleNotFound = 0x90
	case OutOfBoundary = 0x91
	case IllegalFileName = 0x92
	case IllegalHandle = 0x93
}
