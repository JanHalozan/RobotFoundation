//
//  NSDataNXTExtras.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import Foundation

extension String {
	var dataForFilename: Data {
		let clippedName = utf8.count > 19 ? String(utf8.prefix(19))! : self as String
		let paddedName = clippedName.padding(toLength: 20, withPad: "\0", startingAt: 0)

		return paddedName.data(using: .utf8) ?? Data()
	}
}

extension Data {
	mutating func appendNXTFilename(_ filename: String) {
		append(filename.dataForFilename)
	}

	mutating func appendNXTBrickName(_ name: String) {
		let clippedName = name.utf8.count > 15 ? String(name.utf8.prefix(15))! : name
		let paddedName = clippedName.appending("\0")

		guard let data = paddedName.data(using: .utf8) else {
			assertionFailure()
			return
		}

		append(data)
	}
}
