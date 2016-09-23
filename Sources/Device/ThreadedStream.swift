//
//  ThreadedStream.swift
//  RobotFoundation
//
//  Created by Matt on 9/23/16.
//  Copyright © 2016 Matt Rajca. All rights reserved.
//

import Foundation

class ThreadedStream: NSObject, StreamDelegate {
	fileprivate let stream: Stream
	fileprivate var thread: Thread?

	fileprivate init(stream: Stream) {
		self.stream = stream
	}

	func open() {
		assert(self.thread == nil)

		let thread = Thread(target: self, selector: #selector(runThread), object: nil)
		thread.qualityOfService = .userInitiated
		thread.start()
		self.thread = thread

		perform(#selector(openStream), on: thread, with: nil, waitUntilDone: false)
	}

	private let kStatusKey: NSString = "status"

	var streamStatus: Stream.Status {
		guard let thread = thread else {
			return .notOpen
		}

		let dictionary = NSMutableDictionary()
		perform(#selector(getStatus), on: thread, with: dictionary, waitUntilDone: true)
		return dictionary.object(forKey: kStatusKey) as! Stream.Status
	}

	@objc private func getStatus(_ dictionary: NSMutableDictionary) {
		assert(!Thread.isMainThread)
		dictionary.setObject(stream.streamStatus, forKey: kStatusKey)
	}

	@objc private func runThread() {
		assert(!Thread.isMainThread)

		while !(thread?.isFinished ?? false) {
			RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
		}
	}

	@objc private func openStream() {
		assert(!Thread.isMainThread)

		stream.schedule(in: .current, forMode: .commonModes)
		stream.delegate = self
		stream.open()
	}

	func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		fatalError()
	}
}

protocol ThreadedInputStreamDelegate: class {
	func threadedInputStreamDidClose()
	func threadedInputStreamDidReceiveData(data: Data)
}

private extension InputStream {
	func readUntilBlocked() -> Data {
		var continueReading = false
		var allData = Data()
		repeat {
			let bufferLength = 1024
			var buffer = Data(count: bufferLength)
			let bytesRead = buffer.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
				return read(pointer, maxLength: bufferLength)
			}

			if bytesRead < bufferLength {
				continueReading = false
			} else {
				continueReading = true
			}
			allData.append(buffer.subdata(in: 0..<bytesRead))
		} while continueReading
		return allData
	}
}

final class ThreadedInputStream: ThreadedStream {
	weak var delegate: ThreadedInputStreamDelegate?

	init(stream: InputStream, delegate: ThreadedInputStreamDelegate) {
		self.delegate = delegate
		super.init(stream: stream)
	}

	fileprivate var inputStream: InputStream {
		return stream as! InputStream
	}

	override func stream(_ aStream: Stream, handle event: Stream.Event) {
		assert(!Thread.isMainThread)

		if event.contains(.hasBytesAvailable) {
			let data = inputStream.readUntilBlocked()
			delegate?.threadedInputStreamDidReceiveData(data: data)
		}

		if event.contains(.errorOccurred) || event.contains(.endEncountered) {
			delegate?.threadedInputStreamDidClose()
		}
	}
}

final class ThreadedOutputStream: ThreadedStream {
	private let queue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	init(stream: OutputStream) {
		super.init(stream: stream)
	}

	fileprivate var outputStream: OutputStream {
		return stream as! OutputStream
	}

	func writeData(data: Data) {
		let operation = WriteDataOperation(stream: self, data: data)
		queue.addOperation(operation)
	}

	override func stream(_ aStream: Stream, handle event: Stream.Event) {
		assert(!Thread.isMainThread)

		if event.contains(.openCompleted) {
			// Nudge the operations.
			for operation in queue.operations {
				operation.willChangeValue(forKey: "isReady")
				operation.didChangeValue(forKey: "isReady")
			}
		}
	}
}

private class StreamOperation: Operation {
	fileprivate weak var stream: ThreadedStream?

	init(stream: ThreadedStream) {
		self.stream = stream
		super.init()
	}

	override var isReady: Bool {
		guard let state = stream?.streamStatus else {
			return false
		}

		switch state {
		case .open:
			return true
		default:
			return false
		}
	}
}

private final class WriteDataOperation: StreamOperation {
	private let data: Data

	init(stream: ThreadedOutputStream, data: Data) {
		self.data = data
		super.init(stream: stream)
	}

	private var outputStream: ThreadedOutputStream? {
		if let stream = self.stream {
			return stream as? ThreadedOutputStream
		}
		else {
			return nil
		}
	}

	@objc private func writeData(_ data: Data) {
		guard let outputStream = outputStream else {
			assertionFailure()
			return
		}

		let bytesWritten = data.withUnsafeBytes { bytes in
			return outputStream.outputStream.write(bytes, maxLength: data.count)
		}

		if bytesWritten < data.count {
			print("\(#function): not all bytes could be written")
		}
	}

	override func main() {
		guard let thread = outputStream?.thread else {
			assertionFailure()
			return
		}

		perform(#selector(writeData), on: thread, with: data, waitUntilDone: true)
	}
}
