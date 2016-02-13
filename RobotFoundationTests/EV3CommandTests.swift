//
//  EV3CommandTests.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import XCTest
@testable import RobotFoundation

final class EV3CommandTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testPlayToneCommand() {
		let command = EV3PlayToneCommand(volume: 3, frequency: 1000, duration: 1000)

		// From the EV3 Communication docs, the payload should be:
		// 0F00xxxx8000009401810282E80382E803
		// where xxxx is a monotonically-increasing message counter.

		var expectedBytes: [UInt8] = [ 0xF, 0x0, 0x0, 0x0, 0x00, 0x0, 0x0, 0x94, 0x01, 0x81, 0x02, 0x82, 0xE8, 0x03, 0x82, 0xE8, 0x03 ]
		assert(expectedBytes.count == 17)
		let expectedData = NSData(bytes: &expectedBytes, length: expectedBytes.count)
		let data = command.formEV3PacketData(0, prependTotalLength: false)
		XCTAssertTrue(data.isEqualToData(expectedData))
	}
}
