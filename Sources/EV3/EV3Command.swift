//
//  EV3Command.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public protocol EV3Command: MindstormsCommand { }

public protocol EV3DirectCommand: EV3Command {
	var globalSpaceSize: UInt16 { get } // 0-1023

	func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data
}

extension EV3DirectCommand {
	public var globalSpaceSize: UInt16 {
		return 0
	}

	public var type: MindstormsCommandType {
		return .direct
	}
}

public protocol EV3SystemCommand: EV3Command {
	var systemCommand: UInt8 { get }

	var payloadData: Data { get }
}

extension EV3SystemCommand {
	public var type: MindstormsCommandType {
		return .system
	}
}
