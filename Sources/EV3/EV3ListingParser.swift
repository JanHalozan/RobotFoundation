//
//  EV3ListingParser.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

public enum EV3Entry {
	case Folder(name: String)
	case File(name: String, md5: String, fileSizeHex: String)
}

func entriesForListingString(string: String) -> [EV3Entry] {
	var entries = [EV3Entry]()

	string.enumerateLines { line, stop in
		if line == "./" || line == "../" {
			// Ignore these
			return
		} else if line.hasSuffix("/") {
			// Folder
			entries.append(.Folder(name: line))
		} else {
			// File
			let md5 = line.substringToIndex(line.startIndex.advancedBy(32))
			let fileSizeHex = line.substringWithRange(Range<String.Index>(start: line.startIndex.advancedBy(33), end: line.startIndex.advancedBy(41)))
			let name = line.substringFromIndex(line.startIndex.advancedBy(42))
			entries.append(.File(name: name, md5: md5, fileSizeHex: fileSizeHex))
		}
	}

	return entries
}
