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

	func robotDeviceManagerDidLoseDevice(device: MetaDevice) { }

	func robotDeviceManagerDidFindDevice(device: MetaDevice) {
		assert(Thread.isMainThread)

		self.device = EV3Device(metaDevice: device)
		try! self.device.open()

		activeTest()
	}

	func testPlayToneCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3PlayToneCommand(volume: 3, frequency: 1000, duration: 1000)
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
				XCTAssertEqual(ev3Response.color, EV3SensorColor.White)
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
			let modeCommand = EV3GetVersionCommand(version: .OS)
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
			let modeCommand = EV3SetMotorSpeedCommand(ports: .A, speed: 10)
			self.device.enqueueCommand(modeCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let startCommand = EV3StartMotorCommand(ports: .A)
			self.device.enqueueCommand(startCommand, responseHandler: { response in
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

	func testFolderListingCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3ListFilesCommand(path: "../apps/")
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3ListingResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testFirmwareVersionCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3GetVersionCommand(version: .Firmware)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3StringResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				XCTAssertEqual(ev3Response.string, "V1.06H")
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testHardwareVersionCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3GetVersionCommand(version: .Hardware)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3StringResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				XCTAssertEqual(ev3Response.string, "V0.60")
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testSDCardCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3GetStorageInfoCommand()
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3StorageResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testButtonPress() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3IsButtonPressedCommand(button: .Left)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3ButtonPressedResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				XCTAssertTrue(ev3Response.pressed)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testFillWindowCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3FillWindowCommand(color: EV3FillColorConst.Background)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			// no drawing happens until this call
			let updateCommand = EV3UpdateDisplayCommand()
			self.device.enqueueCommand(updateCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testDrawTextCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3FillWindowCommand(color: EV3FillColorConst.Background)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let drawRect = EV3DrawRectCommand(color: EV3FillColorConst.Foreground, x: 6, y: 52, width: 166, height: 24)
			self.device.enqueueCommand(drawRect) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let textCommand = EV3DrawTextCommand(color: EV3FillColorConst.Foreground, x: 13, y: 60, string: "Alex is awesome!", fontSize: .Small)
			self.device.enqueueCommand(textCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			// no drawing happens until this call
			let updateCommand = EV3UpdateDisplayCommand()
			self.device.enqueueCommand(updateCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testInvertRectCommand() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let disableTopline = EV3EnableToplineCommand(enable: false)
			self.device.enqueueCommand(disableTopline) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let command = EV3FillWindowCommand(color: EV3FillColorConst.Background)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let drawRect = EV3InvertRectCommand(x: 6, y: 52, width: 166, height: 24)
			self.device.enqueueCommand(drawRect) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			// no drawing happens until this call
			let updateCommand = EV3UpdateDisplayCommand()
			self.device.enqueueCommand(updateCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}

	func testPrimitiveDrawingCommands() {
		responseExpectation = expectationWithDescription("command response")
		activeTest = { [unowned self] in
			let command = EV3FillWindowCommand(color: .Background)
			self.device.enqueueCommand(command) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let drawPixel = EV3DrawPixelCommand(color: .Foreground, x: 40, y: 40)
			self.device.enqueueCommand(drawPixel) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let drawLine = EV3DrawLineCommand(color: .Foreground, x1: 20, y1: 20, x2: 40, y2: 20)
			self.device.enqueueCommand(drawLine) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let drawDotline = EV3DrawDotlineCommand(color: .Foreground, x1: 60, y1: 20, x2: 80, y2: 20, onPixels: 1, offPixels: 1)
			self.device.enqueueCommand(drawDotline) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let circle = EV3DrawCircleCommand(color: .Foreground, x: 100, y: 100, radius: 8)
			self.device.enqueueCommand(circle) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			let filledCircle = EV3FillCircleCommand(color: .Foreground, x: 40, y: 100, radius: 8)
			self.device.enqueueCommand(filledCircle) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
			}

			// no drawing happens until this call
			let updateCommand = EV3UpdateDisplayCommand()
			self.device.enqueueCommand(updateCommand) { response in
				let ev3Response = response as! EV3GenericResponse
				XCTAssertEqual(ev3Response.replyType, EV3ReplyType.Success)
				self.responseExpectation.fulfill()
			}
		}

		manager.beginDiscovery()
		waitForExpectationsWithTimeout(10, handler: nil)
	}
}
