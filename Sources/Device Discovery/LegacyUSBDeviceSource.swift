//
//  LegacyUSBDeviceSource.swift
//  RobotFoundation
//
//  Created by Matt on 6/30/16.
//

#if os(OSX)

import Foundation
import IOKit.usb

extension io_iterator_t {
	func enumerate(@noescape handler: io_service_t -> ()) {
		var device = io_service_t()
		repeat {
			device = IOIteratorNext(self)
			if device != 0 {
				handler(device)
			}
		} while (device != 0)
	}
}

private func matchingDictionaryForProductID(productID: Int, vendorID: Int) -> [String: AnyObject] {
	guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) else {
		assertionFailure()
		return [:]
	}

	let matchingDictSwift = matchingDict as NSMutableDictionary
	matchingDictSwift[kUSBVendorID] = vendorID
	matchingDictSwift[kUSBProductID] = productID

	return (matchingDictSwift.copy() as! NSDictionary) as! [String: AnyObject]
}

private func matchingDevicesForProductID(productID: Int, vendorID: Int) -> [MetaDevice]? {
	let matchingDict = matchingDictionaryForProductID(productID, vendorID: vendorID)

	var iterator = io_iterator_t()
	if (IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator) != kIOReturnSuccess) {
		return nil
	}

	var devices = [MetaDevice]()
	iterator.enumerate { device in
		guard let robotDevice = robotDeviceForService(device) else {
			assertionFailure()
			return
		}
		devices.append(robotDevice)
	}
	IOObjectRelease(iterator)

	return devices
}

private func robotDeviceForService(service: io_service_t) -> MetaDevice? {
	guard let uniqueIdentifier = IORegistryEntrySearchCFProperty(service, kIOServicePlane, kUSBSerialNumberString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively)) as? String else {
		assertionFailure()
		return nil
	}

	let name = IORegistryEntrySearchCFProperty(service, kIOServicePlane, kUSBProductString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively)) as? String ?? "NXT USB"
	return MetaDevice(type: .LegacyUSBDevice, deviceClass: .NXT20, uniqueIdentifier: uniqueIdentifier, name: name)
}

public final class LegacyUSBDeviceSource: RobotDeviceSource {
	private unowned var client: RobotDeviceSourceClient
	private var foundDevices = Set<MetaDevice>()

	public init(client: RobotDeviceSourceClient) {
		self.client = client
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes)
	}

	deinit {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes)
		IONotificationPortDestroy(notificationPort)
	}

	private lazy var notificationPort: IONotificationPortRef = {
		IONotificationPortCreate(kIOMasterPortDefault)
	}()

	private lazy var runLoopSource: CFRunLoopSource = { [unowned self] in
		IONotificationPortGetRunLoopSource(self.notificationPort).takeUnretainedValue()
	}()

	public func beginDiscovery(searchCriteria: [RobotDeviceDescriptor]) {
		// FIXME: NXT 2.0 is hardcoded here because that's the only device that uses this; fix it later.
		guard let currentDevices = matchingDevicesForProductID(0x2, vendorID: 0x694) else {
			assertionFailure()
			return
		}

		foundDevices = Set<MetaDevice>(currentDevices)

		// FIXME: NXT 2.0 is hardcoded here because that's the only device that uses this; fix it later.
		let matchingDict = matchingDictionaryForProductID(0x2, vendorID: 0x694)

		var matchIterator = io_iterator_t()
		var removeIterator = io_iterator_t()

		var mutableSelf = self
		withUnsafeMutablePointer(&mutableSelf) { selfPointer in
			IOServiceAddMatchingNotification(notificationPort, kIOMatchedNotification, matchingDict, { pointer, iterator in
				let source = unsafeBitCast(pointer, UnsafeMutablePointer<LegacyUSBDeviceSource>.self)
				iterator.enumerate { device in
					guard let robotDevice = robotDeviceForService(device) else {
						assertionFailure()
						return
					}
					source.memory.foundDevices.insert(robotDevice)
					source.memory.client.robotDeviceSourceDidFindDevice(robotDevice)
				}
			}, selfPointer, &matchIterator);
			IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, matchingDict, { pointer, iterator in
				let source = unsafeBitCast(pointer, UnsafeMutablePointer<LegacyUSBDeviceSource>.self)
				iterator.enumerate { device in
					guard let robotDevice = robotDeviceForService(device) else {
						assertionFailure()
						return
					}
					source.memory.foundDevices.remove(robotDevice)
					source.memory.client.robotDeviceSourceDidLoseDevice(robotDevice)
				}
			}, selfPointer, &removeIterator)
		}

		matchIterator.enumerate { _ in }
		removeIterator.enumerate { _ in }
	}
}

#endif
