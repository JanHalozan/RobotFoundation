//
//  EV3DrawRectCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3DrawRectCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x: UInt16
	private let y: UInt16
	private let width: UInt16
	private let height: UInt16

	public init(color: EV3FillColorConst, x: UInt16, y: UInt16, width: UInt16, height: UInt16) {
		self.color = color
		self.x = x
		self.y = y
		self.width = width
		self.height = height
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(offset: UInt8) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Rect.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendLC2(width)
		mutableData.appendLC2(height)

		return mutableData.copy() as! NSData
	}
}
