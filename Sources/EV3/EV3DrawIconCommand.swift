//
//  EV3DrawIconCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public enum EV3IconType: UInt8 {
	case normal = 0
	case small
	case large
	case menu
	case arrow
}

public enum EV3SmallIconNumber: UInt8 {
	case charging = 0
	case batt4
	case batt3
	case batt2
	case batt1
	case batt0
	case wait1
	case wait2
	case btOn
	case btVisible
	case btConnected
	case btConnectedVisible
	case wiFi3
	case wiFi2
	case wiFi1
	case wiFiConnected
	case usb
}

public enum EV3NormalIconNumber: UInt8 {
	case run = 0
	case folder
	case folder2
	case usb
	case sd
	case sound
	case image
	case settings
	case onOff
	case search
	case wiFi
	case connections
	case iconAddHidden
	case trashBin
	case visibility
	case key
	case connect
	case disconnect
	case up
	case down
	case wait1
	case wait2
	case bluetooth
	case info
	case text

	case questionMark = 27
	case infoFile
	case disc
	case connected
	case obp
	case obd
	case openFolder
	case brick1
}

public enum EV3LargeIconNumber: UInt8 {
	case yesNotSelected = 0
	case yesSelected
	case noNotSelected
	case noSelected
	case off
	case waitVertical
	case waitHorizontal
	case toManual
	case warnSign
	case warnBatt
	case warnTemp
	case noUSBStick
	case toExexcute
	case toBrick
	case toSDCard
	case toUSBStick
	case toBluetooth
	case toWiFi
	case toTrash
	case toCopy
	case toFile
	case charError
	case copyError
	case programError
	case warnMemory = 27
}

public enum EV3MenuIconNumber: UInt8 {
	case star = 0
	case lockStar
	case lock
	case pc
	case phone
	case brick
	case unknown
	case fromFolder
	case checkbox
	case checked
	case xed
}

public enum EV3ArrowIconNumber: UInt8 {
	case left = 1
	case right
}

public struct EV3DrawIconCommand: EV3DirectCommand {
	private let color: EV3FillColorConst
	private let x: UInt16
	private let y: UInt16
	private let type: EV3IconType
	private let number: UInt8

	public init(color: EV3FillColorConst, x: UInt16, y: UInt16, type: EV3IconType, number: UInt8) {
		self.color = color
		self.x = x
		self.y = y
		self.type = type
		self.number = number
	}

	public var responseType: MindstormsResponse.Type {
		return EV3GenericResponse.self
	}

	public func payloadDataWithGlobalOffset(_ offset: UInt16) -> Data {
		var mutableData = Data()
		mutableData.appendUInt8(EV3OpCode.uiDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.icon.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendLC1(type.rawValue)
		mutableData.appendLC1(number)

		return mutableData
	}
}
