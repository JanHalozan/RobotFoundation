//
//  EV3HIDDeviceTests.swift
//  RobotFoundation
//
//  Created by Matt on 12/20/15.
//  Copyright © 2015 Matt Rajca. All rights reserved.
//

import XCTest
@testable import RobotFoundation

final class EV3HIDDeviceTests: XCTestCase, RobotDeviceManagerDelegate {
	private var manager: RobotDeviceManager!
	private var device: EV3Device!
	private var responseExpectation: XCTestExpectation!
	private var activeTest: (() -> ())!

	override func setUp() {
		super.setUp()

		manager = RobotDeviceManager(sourceTypes: [HIDDeviceSource.self], searchCriteria: [RobotDeviceDescriptor.EV3()], delegate: self)
	}

	override func tearDown() {
		device.close()
		super.tearDown()
	}

	func robotDeviceManagerDidFindDevice(device: MetaDevice) {
		assert(NSThread.isMainThread())

		switch device.internalType {
		case let .HIDDevice(hidDevice):
			let transport = HIDDeviceTransport(device: hidDevice)
			self.device = EV3Device(transport: transport)
			try! self.device.open()
		default:
			assertionFailure()
		}

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

		manager.beginDiscovery()
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

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testReadReflectedLightCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3ReadLightCommand(port: .Three, lightType: .Reflected)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3PercentByteResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testReadAmbientLightCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3ReadLightCommand(port: .Three, lightType: .Ambient)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3PercentByteResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testReadWhiteColorCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			// Put the light sensor in 'Color' mode before we read the 'raw' value.
			let modeCommand = EV3SetSensorModeCommand(port: .Three, mode: EV3ColorMode)
			self.device.enqueueCommand(modeCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let command = EV3ReadColorCommand(port: .Three)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3ColorResponse
				XCTAssertEqual(ev3Response.color, EV3Color.White)
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testGetOSVersionCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			// Put the light sensor in 'Color' mode before we read the 'raw' value.
			let modeCommand = EV3GetOSVersionCommand()
			self.device.enqueueCommand(modeCommand) { response in
				let ev3Response = response as! EV3StringResponse
				XCTAssertEqual(ev3Response.string, "Linux 2.6.33-rc4")
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testMotorSpeedCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let modeCommand = EV3SetMotorSpeedCommand(port: .A, speed: 10)
			self.device.enqueueCommand(modeCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let startCommand = EV3StartMotorCommand(port: .A)
			self.device.enqueueCommand(startCommand, responseHandler: { (response) -> () in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			})
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testMotorStopCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let modeCommand = EV3StopMotorCommand(port: .A, stopType: .Coast)
			self.device.enqueueCommand(modeCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}
}
