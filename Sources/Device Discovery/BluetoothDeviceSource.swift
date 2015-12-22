//
//  BluetoothDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation
import IOBluetooth

public final class BluetoothDeviceSource: RobotDeviceSource, IOBluetoothDeviceInquiryDelegate {
	private let deviceInquiry: IOBluetoothDeviceInquiry

	private unowned var client: RobotDeviceSourceClient

	public init(client: RobotDeviceSourceClient) {
		self.deviceInquiry = IOBluetoothDeviceInquiry()
		self.client = client
		deviceInquiry.delegate = self
	}

	public func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		deviceInquiry.stop()

		deviceInquiry.setSearchCriteria(BluetoothServiceClassMajor(kBluetoothServiceClassMajorAny), majorDeviceClass: BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorToy), minorDeviceClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorToyRobot))
		deviceInquiry.start()
	}

	@objc public func deviceInquiryDeviceFound(sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
		client.robotDeviceSourceDidFindDevice(RobotDevice(bluetoothDevice: device))
	}
}
