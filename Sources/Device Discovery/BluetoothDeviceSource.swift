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
	private var foundDevices = Set<MetaDevice>()
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
	#if !DEBUG
		deviceInquiry.setSearchCriteria(BluetoothServiceClassMajor(kBluetoothServiceClassMajorAny), majorDeviceClass: BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorToy), minorDeviceClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorToyRobot))
	#endif
		let result = deviceInquiry.start()

		if result != kIOReturnSuccess {
			print("Could not start looking for Bluetooth devices: \(result)")
		}
	}

	private func hasBluetoothDeviceWithAddress(address: String) -> Bool {
		for metaDevice in foundDevices {
			if case RobotDeviceTypeInternal.BluetoothDevice(let bluetoothDevice) = metaDevice.internalType where bluetoothDevice.addressString == address {
				return true
			}
		}

		return false
	}

	@objc public func deviceInquiryDeviceFound(sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
		assert(NSThread.isMainThread())

		guard !hasBluetoothDeviceWithAddress(device.addressString) else {
			return
		}

		device.performSDPQuery(self)

		// Insert this to the set of local devices immediately so device removal still works, but delay
		// telling the client until we have service information.
		let robotDevice = MetaDevice(bluetoothDevice: device)
		foundDevices.insert(robotDevice)
	}

	private func metaDeviceForBluetoothDevice(device: IOBluetoothDevice) -> MetaDevice? {
		for foundDevice in foundDevices {
			if case RobotDeviceType.BluetoothDevice(let bd) = foundDevice.type where bd === device {
				return foundDevice
			}
		}

		return nil
	}

	@objc private func sdpQueryComplete(device: IOBluetoothDevice!, status: IOReturn) {
		guard let robotDevice = metaDeviceForBluetoothDevice(device) else {
			assertionFailure()
			return
		}

		client.robotDeviceSourceDidFindDevice(robotDevice)
	}

	@objc public func deviceInquiryComplete(sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
		// If the inquiry was aborted we don't have any interesting new information.
		guard !aborted else {
			return
		}

		guard let bluetoothDevices = deviceInquiry.foundDevices() as? [IOBluetoothDevice] else {
			assertionFailure()
			return
		}

		// Check for found devices that aren't in device inquiry's set of results.
		// These disappeared since the last scan.
		var devicesToRemove = Set<MetaDevice>()

		for foundDevice in foundDevices {
			if !bluetoothDevicesContainRobotDevice(bluetoothDevices, foundDevice) {
				client.robotDeviceSourceDidLoseDevice(foundDevice)
				devicesToRemove.insert(foundDevice)
			}
		}

		foundDevices.subtractInPlace(devicesToRemove)

		scanTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(scanAgain), userInfo: nil, repeats: false)
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
