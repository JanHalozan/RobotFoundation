//
//  Atomic.swift
//  RobotFoundation
//
//  Created by Matt on 8/7/16.
//

import Foundation

protocol Initializable {
	init()
}

final class SimpleAtomic<T where T: Initializable> {
	private var value: T
	private let queue = dispatch_queue_create(nil, nil)

	init() {
		value = T()
	}

	func set(value: T) {
		dispatch_barrier_async(queue) {
			self.value = value
		}
	}

	func get() -> T {
		var result = T()
		dispatch_sync(queue) {
			result = self.value
		}
		return result
	}
}

// Support for common types.
extension Bool: Initializable { }
