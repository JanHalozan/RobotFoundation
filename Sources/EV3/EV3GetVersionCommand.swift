//
//  EV3GetFWVersionCommand.swift
//  RobotFoundation
//
//  Created by Matt on 12/27/15.
//

import Foundation

public enum EV3Version: UInt8 {
	case os = 3
	case hardware = 9
	case firmware = 10
	case firmwareBuild = 11
	case osBuild = 12
}

public struct EV3GetVersionCommand: EV3DirectCommand {
	public let version: EV3Version

	public init(version: EV3Version) {
		self.version = version
	}

	public var responseType: MindstormsResponse.Type {
		return EV3StringResponse.self
	}

	public var globalSpaceSize: UInt16 {
		return EV3MaxFileLength
	}
	
	public var responseInfo: [String: Any] {
		return [kResponseMaxLengthKey: Int(EV3MaxFileLength)]
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiRead.rawValue)
		mutableData.appendUInt8(version.rawValue)
		mutableData.appendLC2(UInt16(EV3MaxFileLength))
		mutableData.appendGV2(offset)

		return mutableData
	}
}
