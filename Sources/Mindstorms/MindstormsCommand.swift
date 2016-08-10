//
//  MindstormsCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

public let kDirectTelegramType = UInt8(0x0)
public let kSystemTelegramType = UInt8(0x1)

public protocol MindstormsCommand {
	var responseType: MindstormsResponse.Type { get }
	var type: MindstormsCommandType { get }

	// Info dictionary that is passed to MindstormsResponses.
	var responseInfo: [String : Any] { get }
}

extension MindstormsCommand {
	var telegramType: UInt8 {
		switch type {
		case .Direct:
			return kDirectTelegramType
		case .System:
			return kSystemTelegramType
		}
	}

	public var responseInfo: [String : Any] {
		return [:]
	}
}
