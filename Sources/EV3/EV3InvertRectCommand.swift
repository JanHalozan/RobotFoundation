//
//  EV3InvertRectCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3InvertRectCommand: EV3DirectCommand {
	private let x: UInt16
	private let y: UInt16
	private let width: UInt16
	private let height: UInt16

	public init(x: UInt16, y: UInt16, width: UInt16, height: UInt16) {
		self.x = x
		self.y = y
		self.width = width
		self.height = height
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.inverseRect.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendLC2(width)
		mutableData.appendLC2(height)

		return mutableData
	}
}
