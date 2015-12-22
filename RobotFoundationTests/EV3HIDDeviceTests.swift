//
//  EV3HIDDeviceTests.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

import XCTest
@testable import RobotFoundation

final class EV3HIDDeviceTests: XCTestCase, HIDDeviceManagerDelegate {
	private var manager: HIDDeviceManager!
	private var device: EV3Device!
	private var responseExpectation: XCTestExpectation!
	private var activeTest: (() -> ())!

	override func setUp() {
		super.setUp()

		manager = HIDDeviceManager(delegate: self)
	}

	override func tearDown() {
		device.close()
		super.tearDown()
	}

	func HIDDeviceManagerFoundDevice(hidDevice: IOHIDDeviceRef) {
		assert(NSThread.isMainThread())

		let transport = HIDDeviceTransport(device: hidDevice)
		device = EV3Device(transport: transport)
		try! device.open()

		activeTest()
	}

	func testPlayToneCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3PlayToneCommand(frequency: 1000, duration: 1000)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		do {
			try manager.searchForEV3Devices()
		} catch {
			XCTFail("Could not begin search for EV3 devices")
		}

		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testTouchSensorOn() {
		_testTouchSensorCommandIsOn(true)
	}

	func testTouchSensorOff() {
		_testTouchSensorCommandIsOn(false)
	}

	func _testTouchSensorCommandIsOn(isOn: Bool) {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3ReadTouchSensorCommand(port: .Three)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3PercentByteResponse
				XCTAssertEqual(ev3Response.percent, isOn ? 100 : 0)
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		do {
			try manager.searchForEV3Devices()
		} catch {
			XCTFail("Could not begin search for EV3 devices")
		}

		waitForExpectationsWithTimeout(10, handler: nil)
	}
}
