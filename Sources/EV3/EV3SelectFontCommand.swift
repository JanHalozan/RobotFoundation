//
//  EV3SelectFontCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public enum EV3Font: UInt8 {
	case Small = 0
	case Medium = 1
	case Large = 2
}

public struct EV3SelectFontCommand: EV3DirectCommand {
	private let font: EV3Font

	public init(font: EV3Font) {
		self.font = font
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.SelectFont.rawValue)
		mutableData.appendUInt8(font.rawValue)

		return mutableData.copy() as! NSData
	}
}
