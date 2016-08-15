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
	private weak var scanTimer: NSTimer?

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

		// FIXME: get these fields on search criteria structs
		deviceInquiry.setSearchCriteria(BluetoothServiceClassMajor(kBluetoothServiceClassMajorAny), majorDeviceClass: BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorToy), minorDeviceClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorToyRobot))

		let result = deviceInquiry.start()

		if result != kIOReturnSuccess {
			print("Could not start looking for Bluetooth devices: \(result)")
		}
	}

	private func hasBluetoothDeviceWithAddress(address: String) -> Bool {
		for metaDevice in foundDevices {
			if case RobotDeviceType.BluetoothDevice = metaDevice.type where metaDevice.uniqueIdentifier == address {
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

		// We'll fill in the device class when the SDP query completes.
		let metaDevice = MetaDevice(type: .BluetoothDevice, deviceClass: .Unknown, uniqueIdentifier: device.addressString, name: device.name ?? "Bluetooth Device")
		foundDevices.insert(metaDevice)
	}

	private func metaDeviceForBluetoothDevice(device: IOBluetoothDevice) -> MetaDevice? {
		for foundDevice in foundDevices {
			if case RobotDeviceType.BluetoothDevice = foundDevice.type {
				if foundDevice.uniqueIdentifier == device.addressString {
					return foundDevice
				}
			}
		}

		return nil
	}

	@objc private func sdpQueryComplete(device: IOBluetoothDevice!, status: IOReturn) {
		assert(NSThread.isMainThread())

		guard let metaDevice = metaDeviceForBluetoothDevice(device) else {
			assertionFailure()
			return
		}

		metaDevice.deviceClass = deviceClassForBluetoothDevice(device)

		client.robotDeviceSourceDidFindDevice(metaDevice)
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
		deviceInquiry.stop()
		deviceInquiry.clearFoundDevices()
		deviceInquiry.start()
	}
}

private func deviceClassForBluetoothDevice(bluetoothDevice: IOBluetoothDevice) -> DeviceClass {
	guard let services = bluetoothDevice.services as? [IOBluetoothSDPServiceRecord] else {
		return .Unknown
	}

	guard let firstService = services.first else {
		assertionFailure()
		return .Unknown
	}

	guard let platform = firstService.attributes[258] as? IOBluetoothSDPDataElement else {
		// Hacky, but the NXTs don't have this key.
		return .NXT20
	}

	guard platform.getStringValue().containsString("BlueZ") else {
		return .NXT20
	}

	return .EV3
}

private func bluetoothDevicesContainRobotDevice(bluetoothDevices: [IOBluetoothDevice], _ robotDevice: MetaDevice) -> Bool {
	guard case RobotDeviceType.BluetoothDevice = robotDevice.type else {
		return false
	}

	for bluetoothDevice in bluetoothDevices {
		if bluetoothDevice.addressString == robotDevice.uniqueIdentifier {
			return true
		}
	}

	return false
}

#endif
