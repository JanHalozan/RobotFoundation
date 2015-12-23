//
//  EV3ListingParser.swift
//  RobotFoundation
//
//  Created by Matt on 12/23/15.
//

import Foundation

protocol EV3Entry { }

struct EV3FolderEntry: EV3Entry {
	let name: String
}

struct EV3FileEntry: EV3Entry {
	let md5: String
	let fileSizeHex: String
	let name: String
}

func entriesForListingString(string: String) -> [EV3Entry] {
	var entries = [EV3Entry]()

	string.enumerateLines { line, stop in
		if line == "./" || line == "../" {
			// Ignore these
			return
		} else if line.hasSuffix("/") {
			// Folder
			entries.append(EV3FolderEntry(name: line))
		} else {
			// File
			let md5 = line.substringToIndex(line.startIndex.advancedBy(32))
			let fileSizeHex = line.substringWithRange(Range<String.Index>(start: line.startIndex.advancedBy(33), end: line.startIndex.advancedBy(41)))
			let name = line.substringFromIndex(line.startIndex.advancedBy(42))
			entries.append(EV3FileEntry(md5: md5, fileSizeHex: fileSizeHex, name: name))
		}
	}

	return entries
}
