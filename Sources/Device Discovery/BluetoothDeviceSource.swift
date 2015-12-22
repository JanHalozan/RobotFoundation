//
//  BluetoothDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 12/21/15.
//

import Foundation
import IOBluetooth

final class BluetoothDeviceSource: RobotDeviceSource, IOBluetoothDeviceInquiryDelegate {
	private let deviceInquiry: IOBluetoothDeviceInquiry

	private unowned var client: RobotDeviceSourceClient

	init(client: RobotDeviceSourceClient) {
		self.deviceInquiry = IOBluetoothDeviceInquiry()
		self.client = client
		deviceInquiry.delegate = self
	}

	func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		deviceInquiry.stop()

		deviceInquiry.setSearchCriteria(BluetoothServiceClassMajor(kBluetoothServiceClassMajorAny), majorDeviceClass: BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorAny), minorDeviceClass: BluetoothDeviceClassMinor(kBluetoothDeviceClassMinorAny))
		deviceInquiry.start()
	}

	@objc func deviceInquiryDeviceFound(sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
		client.robotDeviceSourceDidFindDevice(RobotDevice(bluetoothDevice: device))
	}
}
