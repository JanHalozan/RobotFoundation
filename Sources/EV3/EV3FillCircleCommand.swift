//
//  EV3FillCircleCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/23/16.
//

import Foundation

public struct EV3FillCircleCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x: UInt16
	private let y: UInt16
	private let radius: UInt16

	public init(color: EV3FillColorConst, x: UInt16, y: UInt16, radius: UInt16) {
		self.color = color
		self.x = x
		self.y = y
		self.radius = radius
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.fillCircle.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendLC2(radius)

		return mutableData
	}
}
