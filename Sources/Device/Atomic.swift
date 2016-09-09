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

final class SimpleAtomic<T> where T: Initializable {
	private var value: T
	private let queue = DispatchQueue(label: "atomic", attributes: [])

	init() {
		value = T()
	}

	func set(_ value: T) {
		queue.async(flags: .barrier) {
			self.value = value
		}
	}

	func get() -> T {
		var result = T()
		queue.sync {
			result = self.value
		}
		return result
	}
}

// Support for common types.
extension Bool: Initializable { }
