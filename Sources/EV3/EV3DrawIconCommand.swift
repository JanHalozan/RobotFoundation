//
//  EV3DrawIconCommand.swift
//  RobotFoundation
//
//  Created by Matt on 1/24/16.
//

import Foundation

public enum EV3IconType: UInt8 {
	case Normal = 0
	case Small
	case Large
	case Menu
	case Arrow
}

public enum EV3SmallIconNumber: UInt8 {
	case Charging = 0
	case Batt4
	case Batt3
	case Batt2
	case Batt1
	case Batt0
	case Wait1
	case Wait2
	case BtOn
	case BtVisible
	case BtConnected
	case BtConnectedVisible
	case WiFi3
	case WiFi2
	case WiFi1
	case WiFiConnected
	case USB
}

public enum EV3NormalIconNumber: UInt8 {
	case Run = 0
	case Folder
	case Folder2
	case USB
	case SD
	case Sound
	case Image
	case Settings
	case OnOff
	case Search
	case WiFi
	case Connections
	case IconAddHidden
	case TrashBin
	case Visibility
	case Key
	case Connect
	case Disconnect
	case Up
	case Down
	case Wait1
	case Wait2
	case Bluetooth
	case Info
	case Text

	case QuestionMark = 27
	case InfoFile
	case Disc
	case Connected
	case OBP
	case OBD
	case OpenFolder
	case Brick1
}

public enum EV3LargeIconNumber: UInt8 {
	case YesNotSelected = 0
	case YesSelected
	case NoNotSelected
	case NoSelected
	case Off
	case WaitVertical
	case WaitHorizontal
	case ToManual
	case WarnSign
	case WarnBatt
	case WarnTemp
	case NoUSBStick
	case ToExexcute
	case ToBrick
	case ToSDCard
	case ToUSBStick
	case ToBluetooth
	case ToWiFi
	case ToTrash
	case ToCopy
	case ToFile
	case CharError
	case CopyError
	case ProgramError
	case WarnMemory = 27
}

public enum EV3MenuIconNumber: UInt8 {
	case Star = 0
	case LockStar
	case Lock
	case PC
	case Phone
	case Brick
	case Unknown
	case FromFolder
	case Checkbox
	case Checked
	case Xed
}

public enum EV3ArrowIconNumber: UInt8 {
	case Left = 1
	case Right
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

	public var payloadData: NSData {
		let mutableData = NSMutableData()
		mutableData.appendUInt8(EV3OpCode.UIDraw.rawValue)
		mutableData.appendUInt8(EV3UIDrawOpSubcode.Icon.rawValue)
		mutableData.appendUInt8(color.rawValue)
		mutableData.appendLC2(x)
		mutableData.appendLC2(y)
		mutableData.appendLC1(type.rawValue)
		mutableData.appendLC1(number)

		return mutableData.copy() as! NSData
	}
}
