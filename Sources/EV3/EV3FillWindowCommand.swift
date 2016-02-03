//
//  EV3FillWindowCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public enum EV3FillColorConst: UInt8 {
	case Background = 0
	case Foreground = 1
}

public struct EV3FillWindowCommand: EV3DirectCommand {
	private let color: EV3FillColorConst

	public init(color: EV3FillColorConst) {
		self.color = color
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.FillWindow.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendUInt8(0)
		mutableData.appendUInt8(0)

		return mutableData.copy() as! NSData
	}
}
