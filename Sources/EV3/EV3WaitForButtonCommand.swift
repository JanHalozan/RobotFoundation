//
//  EV3WaitForButtonCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public struct EV3WaitForButtonCommand: EV3DirectCommand {
	public init() { }

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIButton.rawValue)
		mutableData.appendUInt8(EV3ButtonOpSubcode.WaitForPress.rawValue)

		return mutableData.copy() as! NSData
	}
}
