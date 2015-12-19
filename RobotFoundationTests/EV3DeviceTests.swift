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
private let deviceAddress = "00-16-53-40-82-33"

class EV3DeviceTests: XCTestCase {
	private var device: EV3Device!

	override func setUp() {
		super.setUp()

		let bDevice = IOBluetoothDevice(addressString: deviceAddress)

		let transport = IOBluetoothDeviceTransport(bluetoothDevice: bDevice)
		device = EV3Device(transport: transport)
		try! device.open()
	}

	override func tearDown() {
		device.close()
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
