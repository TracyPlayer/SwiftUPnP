//
//  SSDPCocoaAsyncSocketDiscovery.swift
//
//  Copyright (c) 2023 Katoemba Software, (https://rigelian.net/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Berrie Kremers on 03/03/2022.
//

import CocoaAsyncSocket
import Combine
import Foundation
import os.log

class SSDPCocoaAsyncSocketDiscovery: SSDPDiscovery {
    private var multicastSocket: GCDAsyncUdpSocket?

    func startDiscovery(forTypes types: [String]) throws {
        guard multicastSocket == nil else { throw UPnPError.alreadyConnected }

        let multicastSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        multicastSocket.setIPv4Enabled(true)
        multicastSocket.setIPv6Enabled(true)

        try multicastSocket.enableReusePort(true)
        try multicastSocket.enableBroadcast(true)
        try multicastSocket.bind(toPort: multicastUDPPort)
        try multicastSocket.joinMulticastGroup(multicastGroupAddress)
        try multicastSocket.beginReceiving()

        self.types = types
        self.multicastSocket = multicastSocket
    }

    func stopDiscovery() {
        guard let multicastSocket else { return }

        multicastSocket.close()
        self.multicastSocket = nil
        types = []
    }

    func searchRequest() {
        guard let multicastSocket else { return }

        for type in types {
            if let data = searchRequestData(forType: type) {
                multicastSocket.send(data, toHost: multicastGroupAddress, port: multicastUDPPort, withTimeout: 3, tag: type.hashValue)
            }
        }
    }
}

extension SSDPCocoaAsyncSocketDiscovery: GCDAsyncUdpSocketDelegate {
    func udpSocket(_: GCDAsyncUdpSocket, didNotSendDataWithTag _: Int, dueToError _: Error?) {
        stopDiscovery()
    }

    func udpSocketDidClose(_: GCDAsyncUdpSocket, withError _: Error?) {
        stopDiscovery()
    }

    func udpSocket(_: GCDAsyncUdpSocket, didReceive data: Data, fromAddress _: Data, withFilterContext _: Any?) {
        processData(data)
    }
}
