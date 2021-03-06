//
//  EV3DrawDotlineCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3DrawDotlineCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x1: UInt16
	private let y1: UInt16
	private let x2: UInt16
	private let y2: UInt16
	private let onPixels: UInt16
	private let offPixels: UInt16

	public init(color: EV3FillColorConst, x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, onPixels: UInt16, offPixels: UInt16) {
		self.color = color
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
		self.onPixels = onPixels
		self.offPixels = offPixels
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.dotLine.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x1)
		mutableData.appendLC2(y1)
		mutableData.appendLC2(x2)
		mutableData.appendLC2(y2)
		mutableData.appendLC2(onPixels)
		mutableData.appendLC2(offPixels)

		return mutableData
	}
}
