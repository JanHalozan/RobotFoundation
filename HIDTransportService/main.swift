//
//  main.m
//  HIDTransportService
//
//  Created by Matt on 12/26/15.
//

let server = HIDServer()

// Incoming connections are processed on a new thread which this creates (matches XPC).
server.run()

// The hardware code is processed on the main thread.
RunLoop.current.run()
