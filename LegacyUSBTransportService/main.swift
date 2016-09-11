//
//  main.swift
//  RobotFoundation
//
//  Created by Matt on 6/29/16.
//

let server = MachServer(name: "RJKYY38TY2.com.Robotary.Legacy", transportServiceType: LegacyUSBTransportService.self)

// Incoming connections are processed on a new thread which this creates (matches XPC).
server.run()

// The hardware code is processed on the main thread.
RunLoop.current.run()
