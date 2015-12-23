//
//  EV3Command.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public protocol EV3Command: MindstormsCommand { }

public protocol EV3DirectCommand: EV3Command {
	var numberOfGlobals: UInt8 { get }
}

extension EV3DirectCommand {
	var numberOfGlobals: UInt8 {
		return 0
	}

	public var type: MindstormsCommandType {
		return .Direct
	}
}

public protocol EV3SystemCommand: EV3Command {
	var systemCommand: UInt8 { get }
}

extension EV3SystemCommand {
	public var type: MindstormsCommandType {
		return .System
	}
}
