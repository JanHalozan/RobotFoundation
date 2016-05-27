//
//  EV3GetBrickNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/27/16.
//

// TODO: this might be wrong, can it be 0?
private let kEV3MaxBrickNameLength = UInt8(12)

public struct EV3GetBrickNameCommand: EV3DirectCommand {
	public init() {}

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return UInt16(kEV3MaxBrickNameLength)
	}

	public func payloadDataWithGlobalOffset(offset: UInt16) -> NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.COMGet.rawValue)
		mutableData.appendUInt8(EV3COMGetSubcode.GetBrickName.rawValue)
		mutableData.appendLC1(kEV3MaxBrickNameLength)
		mutableData.appendGV2(offset)

		return mutableData.copy() as! NSData
	}
}

