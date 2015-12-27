//
//  BluetoothDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

#if os(OSX)

import Foundation
import IOBluetooth

public final class BluetoothDeviceSource: RobotDeviceSource, IOBluetoothDeviceInquiryDelegate {
	private let deviceInquiry: IOBluetoothDeviceInquiry
	private var foundDevices = [MetaDevice]()
	private var scanTimer: NSTimer?

	private unowned var client: RobotDeviceSourceClient

	public init(client: RobotDeviceSourceClient) {
		self.deviceInquiry = IOBluetoothDeviceInquiry()
		deviceInquiry.inquiryLength = 10 // seconds

		self.client = client
		deviceInquiry.delegate = self
	}

	deinit {
		deviceInquiry.stop()
		scanTimer?.invalidate()
	}

	public func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		deviceInquiry.stop()
		deviceInquiry.clearFoundDevices()

		// TODO: get these fields on search criteria structs
		deviceInquiry.setSearchCriteria(BluetoothServiceClassMajor(kBluetoothServiceClassMajorAny), majorDeviceClass: BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorToy), minorDeviceClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorToyRobot))
		deviceInquiry.start()
	}

	@objc public func deviceInquiryDeviceFound(sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
		assert(NSThread.isMainThread())

		let robotDevice = MetaDevice(bluetoothDevice: device)
		foundDevices.append(robotDevice)
		client.robotDeviceSourceDidFindDevice(robotDevice)
	}

	@objc public func deviceInquiryComplete(sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
		// Check for found devices that aren't in device inquiry's set of results.
		// These disappeared since the last scan.

		let bluetoothDevices = deviceInquiry.foundDevices() as! [IOBluetoothDevice]

		for foundDevice in foundDevices {
			if !bluetoothDevicesContainRobotDevice(bluetoothDevices, foundDevice) {
				client.robotDeviceSourceDidLoseDevice(foundDevice)
			}
		}

		scanTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "scanAgain:", userInfo: nil, repeats: false)
	}

	@objc private func scanAgain(sender: AnyObject) {
		scanTimer = nil
		deviceInquiry.stop()
		deviceInquiry.clearFoundDevices()
		deviceInquiry.start()
	}
}

private func bluetoothDevicesContainRobotDevice(bluetoothDevices: [IOBluetoothDevice], _ robotDevice: MetaDevice) -> Bool {
	guard case RobotDeviceTypeInternal.BluetoothDevice(let device) = robotDevice.internalType else {
		return false
	}

	for bluetoothDevice in bluetoothDevices {
		if bluetoothDevice.addressString == device.addressString {
			return true
		}
	}

	return false
}

#endif
