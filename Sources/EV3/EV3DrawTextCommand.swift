//
//  EV3DrawTextCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public enum EV3FontSizeConst: UInt8 {
	case Small = 0
	case Medium = 1
	case Large = 2
}

public struct EV3DrawTextCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x: UInt16
	private let y: UInt16
	private let string: String
	private let fontSize: EV3FontSizeConst

	public init(color: EV3FillColorConst, x: UInt16, y: UInt16, string: String, fontSize: EV3FontSizeConst) {
		self.color = color
		self.x = x
		self.y = y
		self.string = string
		self.fontSize = fontSize
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.SelectFont.rawValue)
		mutableData.appendUInt8(fontSize.rawValue)
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Text.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendUInt8(0x84)
		mutableData.appendString(string)

		return mutableData.copy() as! NSData
	}
}
