//
//  AtomicBool.swift
//  RobotFoundation
//
//  Created by Matt on 8/7/16.
//

import Foundation

final class AtomicBool {
	private var value: Bool
	private let queue = dispatch_queue_create(nil, nil)

	init() {
		value = false
	}

	func set(value: Bool) {
		dispatch_barrier_async(queue) {
			self.value = value
		}
	}

	func get() -> Bool {
		var result = false
		dispatch_sync(queue) {
			result = self.value
		}
		return result
	}
}
