//
//  EV3ListingParser.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public enum EV3Entry {
	case folder(name: String)
	case file(name: String, md5: String, fileSize: Int)
}

public func parseEV3FileListingWithString(_ string: String) -> [EV3Entry] {
	var entries = [EV3Entry]()

	string.enumerateLines { line, stop in
		if line == "./" || line == "../" {
			// Ignore these
			return
		} else if line.hasSuffix("/") {
			// Folder
			entries.append(.folder(name: line))
		} else {
			// File
			let md5 = line.substring(to: line.characters.index(line.startIndex, offsetBy: 32))
			let fileSizeHex = line.substring(with: line.characters.index(line.startIndex, offsetBy: 33)..<line.characters.index(line.startIndex, offsetBy: 41))
			let fileSize = Int(fileSizeHex, radix: 16) ?? 0
			let name = line.substring(from: line.characters.index(line.startIndex, offsetBy: 42))
			entries.append(.file(name: name, md5: md5, fileSize: fileSize))
		}
	}

	return entries
}
