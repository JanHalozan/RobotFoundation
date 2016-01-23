//
//  EV3DrawLineCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3DrawLineCommand: EV3DirectCommand {
	private let color: EV3FillColor
	private let x1: UInt16
	private let y1: UInt16
	private let x2: UInt16
	private let y2: UInt16

	public init(color: EV3FillColor, x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16) {
		self.color = color
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Line.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x1)
		mutableData.appendLC2(y1)
		mutableData.appendLC2(x2)
		mutableData.appendLC2(y2)

		return mutableData.copy() as! NSData
	}
}
