//
//  EV3DeviceTests.swift
//  RobotFoundation
//
//  Created by Matt on 12/19/15.
//

import XCTest
import IOBluetoothUI
@testable import RobotFoundation

// This requires a physical EV3 device to be available via Bluetooth.
class EV3DeviceTests: XCTestCase {
	private var device: EV3Device!

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.

		let selector = IOBluetoothDeviceSelectorController.deviceSelector()
		selector.runModal()

		let results = selector.getResults() as! [IOBluetoothDevice]

		let transport = IOBluetoothDeviceTransport(bluetoothDevice: results.first!)
		device = EV3Device(transport: transport)
		try! device.open()
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testPlayToneCommand() {
		let responseExpectation = expectationWithDescription("command response")

		let command = EV3PlayToneCommand(frequency: 1000, duration: 1000)
		device.enqueueCommand(command) { response in
			responseExpectation.fulfill()
		}

		waitForExpectationsWithTimeout(10, handler: nil)
	}
}
