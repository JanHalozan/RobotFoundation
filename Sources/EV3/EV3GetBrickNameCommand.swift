//
//  EV3GetBrickNameCommand.swift
//  RobotFoundation
//
//  Created by Matt on 5/27/16.
//

private let kEV3MaxBrickNameLength = UInt8(12)

public struct EV3GetBrickNameCommand: EV3DirectCommand {
	public init() {}

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return UInt16(kEV3MaxBrickNameLength)
	}
	
	public var responseInfo: [String: Any] {
		return [kResponseMaxLengthKey: Int(kEV3MaxBrickNameLength)]
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.comGet.rawValue)
		mutableData.appendUInt8(EV3COMGetSubcode.getBrickName.rawValue)
		mutableData.appendLC1(kEV3MaxBrickNameLength)
		mutableData.appendGV2(offset)

		return mutableData
	}
}

