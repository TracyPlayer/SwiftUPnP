//
//  UPnPRegistry.swift
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
//  Created by Berrie Kremers on 08/01/2023.
//

import Combine
import Foundation
import os.log

public class UPnPRegistry {
    public static let shared = UPnPRegistry()

    // Use CocoaAsyncSocket discovery for SSDP, as the standard network framework doesn't support when
    // multiple apps connect to the same multicast port (see https://developer.apple.com/forums/thread/716339)
//    private let discoveryEngine = SSDPNetworkDiscovery()
    private let discoveryEngine = SSDPCocoaAsyncSocketDiscovery()
    @MainActor
    public private(set) var devices = [UPnPDevice]()
    private var deviceAddedSubject = PassthroughSubject<UPnPDevice, Never>()
    // devices are always delivered on the main thread.
    public var deviceAdded: AnyPublisher<UPnPDevice, Never> {
        deviceAddedSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private var deviceRemovedSubject = PassthroughSubject<UPnPDevice, Never>()
    // devices are always delivered on the main thread.
    public var deviceRemoved: AnyPublisher<UPnPDevice, Never> {
        deviceRemovedSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private let eventCallBackPath = "/Event/\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    private var eventCallbackUrl: URL?
    private let eventSubject = PassthroughSubject<(String, Data), Never>()
    private lazy var eventPublisher: AnyPublisher<(String, Data), Never> = eventSubject.share().eraseToAnyPublisher()

    private let types: [String]

    public init(types: [String] = ["urn:schemas-upnp-org:service:AVTransport:1", "urn:schemas-upnp-org:device:MediaServer:1", "urn:linn-co-uk:device:Source:1", "urn:av-openhome-org:device:Source:1"],
                httpServerPortRange _: Range<UInt16> = 51000 ..< 51099)
    {
        self.types = types
//            .filter { $0.contains(":device:") }
//        if self.types.count != types.count {
//            Logger.swiftUPnP.error("Only device types are discovered, service types will be discovered indirectly from the device description. Non-device types will be filtered.")
//        }
    }

    public func startDiscovery() throws {
        Task {
            do {
                try discoveryEngine.startDiscovery(forTypes: types)
            } catch {
                print(error)
            }
            discoveryEngine.searchRequest()
        }
    }

    public func stopDiscovery() {
        Task {
            await MainActor.run {
                devices.removeAll(keepingCapacity: false)
            }
        }
        discoveryEngine.stopDiscovery()
    }

    @MainActor
    public func add(_ device: UPnPDevice) {
        guard devices.contains(where: { $0.id == device.id && $0.servicesLoaded == true }) == false else { return }
        devices.removeAll(where: { $0.id == device.id })
        devices.append(device)

        Logger.swiftUPnP.debug("device \(device.id)")
        Task {
            guard await device.loadRoot() == true else {
                Logger.swiftUPnP.error("Failed to load root on \(device.url)")
                return
            }

            if let deviceServices = device.deviceDefinition?.device.serviceList?.service {
                for deviceService in deviceServices {
                    guard let service = typedService(device: device, serviceUrn: deviceService.serviceType) else { continue }

                    await service.loadScdp()
                    device.add(service)
                }
            }

            device.servicesLoaded = true
            deviceAddedSubject.send(device)
        }
    }

    @MainActor
    func remove(_ device: UPnPDevice) {
        guard let device = devices.first(where: { $0.id == device.id }) else { return }
        devices.removeAll(where: { $0.id == device.id })
        deviceRemovedSubject.send(device)
    }

    func typedService(device: UPnPDevice, serviceUrn: String) -> UPnPService? {
        guard let deviceServices = device.deviceDefinition?.device.serviceList?.service,
              let deviceService = deviceServices.first(where: { $0.serviceType == serviceUrn }) else { return nil }

        let baseURL = URL(string: "\(device.url.scheme!)://\(device.url.host!):\(device.url.port!)")
        guard let controlUrl = URL(string: deviceService.controlURL, relativeTo: baseURL),
              let scpdUrl = URL(string: deviceService.SCPDURL, relativeTo: baseURL)
        else {
            return nil
        }
        switch serviceUrn {
        case "urn:schemas-upnp-org:service:ConnectionManager:1":
            return ConnectionManager1Service(device: device,
                                             controlUrl: controlUrl,
                                             scpdUrl: scpdUrl,
                                             eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL),
                                             serviceType: deviceService.serviceType,
                                             serviceId: deviceService.serviceId,
                                             eventPublisher: eventPublisher,
                                             eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:ContentDirectory:1":
            return ContentDirectory1Service(device: device,
                                            controlUrl: controlUrl,
                                            scpdUrl: scpdUrl,
                                            eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL),
                                            serviceType: deviceService.serviceType,
                                            serviceId: deviceService.serviceId,
                                            eventPublisher: eventPublisher,
                                            eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:AVTransport:1":
            return AVTransport1Service(device: device,
                                       controlUrl: controlUrl,
                                       scpdUrl: scpdUrl,
                                       eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL),
                                       serviceType: deviceService.serviceType,
                                       serviceId: deviceService.serviceId,
                                       eventPublisher: eventPublisher,
                                       eventCallbackUrl: eventCallbackUrl)
        case "urn:schemas-upnp-org:service:RenderingControl:1":
            return RenderingControl1Service(device: device,
                                            controlUrl: controlUrl,
                                            scpdUrl: scpdUrl,
                                            eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL),
                                            serviceType: deviceService.serviceType,
                                            serviceId: deviceService.serviceId,
                                            eventPublisher: eventPublisher,
                                            eventCallbackUrl: eventCallbackUrl)
        default:
            return UPnPService(device: device,
                               controlUrl: controlUrl,
                               scpdUrl: scpdUrl,
                               eventUrl: URL(string: deviceService.eventSubURL, relativeTo: baseURL),
                               serviceType: deviceService.serviceType,
                               serviceId: deviceService.serviceId,
                               eventPublisher: eventPublisher,
                               eventCallbackUrl: eventCallbackUrl)
        }
    }
}
