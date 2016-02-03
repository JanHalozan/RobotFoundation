//
//  EV3DrawPixelCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3DrawPixelCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x: UInt16
	private let y: UInt16

	public init(color: EV3FillColorConst, x: UInt16, y: UInt16) {
		self.color = color
		self.x = x
		self.y = y
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Pixel.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)

		return mutableData.copy() as! NSData
	}
}
