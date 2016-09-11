//
//  main.swift
//  BluetoothTransportService
//
//  Created by Matt on 12/26/15.
//

let server = MachServer(name: "RJKYY38TY2.com.Robotary.HID", transportServiceType: BluetoothTransportService.self)

// Incoming connections are processed on a new thread which this creates (matches XPC).
server.run()

// The hardware code is processed on the main thread.
RunLoop.current.run()
