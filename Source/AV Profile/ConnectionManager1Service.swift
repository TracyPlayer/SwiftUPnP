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
//  Generated by SwiftUPnP/UPnPCodeGenerator
//

import Combine
import Foundation
import os.log
import XMLCoder

public class ConnectionManager1Service: UPnPService {
    struct Envelope<T: Codable>: Codable {
        enum CodingKeys: String, CodingKey {
            case body = "s:Body"
        }

        var body: T
    }

    public enum A_ARG_TYPE_ConnectionStatusEnum: String, Codable {
        case ok = "OK"
        case contentFormatMismatch = "ContentFormatMismatch"
        case insufficientBandwidth = "InsufficientBandwidth"
        case unreliableChannel = "UnreliableChannel"
        case unknown = "Unknown"
    }

    public enum A_ARG_TYPE_DirectionEnum: String, Codable {
        case input = "Input"
        case output = "Output"
    }

    public struct GetCurrentConnectionInfoResponse: Codable {
        enum CodingKeys: String, CodingKey {
            case rcsID = "RcsID"
            case aVTransportID = "AVTransportID"
            case protocolInfo = "ProtocolInfo"
            case peerConnectionManager = "PeerConnectionManager"
            case peerConnectionID = "PeerConnectionID"
            case direction = "Direction"
            case status = "Status"
        }

        public var rcsID: Int32
        public var aVTransportID: Int32
        public var protocolInfo: String
        public var peerConnectionManager: String
        public var peerConnectionID: Int32
        public var direction: A_ARG_TYPE_DirectionEnum
        public var status: A_ARG_TYPE_ConnectionStatusEnum

        public func log(deep _: Bool = false, indent: Int = 0) {
            Logger.swiftUPnP.debug("\(Logger.indent(indent))GetCurrentConnectionInfoResponse {")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))rcsID: \(rcsID)")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))aVTransportID: \(aVTransportID)")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))protocolInfo: '\(protocolInfo)'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))peerConnectionManager: '\(peerConnectionManager)'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))peerConnectionID: \(peerConnectionID)")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))direction: \(direction.rawValue)")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))status: \(status.rawValue)")
            Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
        }
    }

    public func getCurrentConnectionInfo(connectionID: Int32, log: UPnPService.MessageLog = .none) async throws -> GetCurrentConnectionInfoResponse {
        struct SoapAction: Codable {
            enum CodingKeys: String, CodingKey {
                case urn = "xmlns:u"
                case connectionID = "ConnectionID"
            }

            @Attribute var urn: String
            public var connectionID: Int32
        }
        struct Body: Codable {
            enum CodingKeys: String, CodingKey {
                case action = "u:GetCurrentConnectionInfo"
                case response = "u:GetCurrentConnectionInfoResponse"
            }

            var action: SoapAction?
            var response: GetCurrentConnectionInfoResponse?
        }
        let result: Envelope<Body> = try await postWithResult(action: "GetCurrentConnectionInfo", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType), connectionID: connectionID))), log: log)

        guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
        return response
    }

    public struct GetProtocolInfoResponse: Codable {
        enum CodingKeys: String, CodingKey {
            case source = "Source"
            case sink = "Sink"
        }

        public var source: String
        public var sink: String

        public func log(deep _: Bool = false, indent: Int = 0) {
            Logger.swiftUPnP.debug("\(Logger.indent(indent))GetProtocolInfoResponse {")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))source: '\(source)'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))sink: '\(sink)'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
        }
    }

    public func getProtocolInfo(log: UPnPService.MessageLog = .none) async throws -> GetProtocolInfoResponse {
        struct SoapAction: Codable {
            enum CodingKeys: String, CodingKey {
                case urn = "xmlns:u"
            }

            @Attribute var urn: String
        }
        struct Body: Codable {
            enum CodingKeys: String, CodingKey {
                case action = "u:GetProtocolInfo"
                case response = "u:GetProtocolInfoResponse"
            }

            var action: SoapAction?
            var response: GetProtocolInfoResponse?
        }
        let result: Envelope<Body> = try await postWithResult(action: "GetProtocolInfo", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

        guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
        return response
    }

    public struct GetCurrentConnectionIDsResponse: Codable {
        enum CodingKeys: String, CodingKey {
            case connectionIDs = "ConnectionIDs"
        }

        public var connectionIDs: String

        public func log(deep _: Bool = false, indent: Int = 0) {
            Logger.swiftUPnP.debug("\(Logger.indent(indent))GetCurrentConnectionIDsResponse {")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))connectionIDs: '\(connectionIDs)'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
        }
    }

    public func getCurrentConnectionIDs(log: UPnPService.MessageLog = .none) async throws -> GetCurrentConnectionIDsResponse {
        struct SoapAction: Codable {
            enum CodingKeys: String, CodingKey {
                case urn = "xmlns:u"
            }

            @Attribute var urn: String
        }
        struct Body: Codable {
            enum CodingKeys: String, CodingKey {
                case action = "u:GetCurrentConnectionIDs"
                case response = "u:GetCurrentConnectionIDsResponse"
            }

            var action: SoapAction?
            var response: GetCurrentConnectionIDsResponse?
        }
        let result: Envelope<Body> = try await postWithResult(action: "GetCurrentConnectionIDs", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)))), log: log)

        guard let response = result.body.response else { throw ServiceParseError.noValidResponse }
        return response
    }
}

// Event parser
public extension ConnectionManager1Service {
    struct State: Codable {
        enum CodingKeys: String, CodingKey {
            case sourceProtocolInfo = "SourceProtocolInfo"
            case sinkProtocolInfo = "SinkProtocolInfo"
            case currentConnectionIDs = "CurrentConnectionIDs"
        }

        public var sourceProtocolInfo: String?
        public var sinkProtocolInfo: String?
        public var currentConnectionIDs: String?

        public func log(deep _: Bool = false, indent: Int = 0) {
            Logger.swiftUPnP.debug("\(Logger.indent(indent))ConnectionManager1ServiceState {")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))sourceProtocolInfo: '\(sourceProtocolInfo ?? "nil")'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))sinkProtocolInfo: '\(sinkProtocolInfo ?? "nil")'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent + 1))currentConnectionIDs: '\(currentConnectionIDs ?? "nil")'")
            Logger.swiftUPnP.debug("\(Logger.indent(indent))}")
        }
    }

    func state(xml: Data) throws -> State {
        struct PropertySet: Codable {
            var property: [State]
        }

        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        let propertySet = try decoder.decode(PropertySet.self, from: xml)

        return propertySet.property.reduce(State()) { partialResult, property in
            var result = partialResult
            if let sourceProtocolInfo = property.sourceProtocolInfo {
                result.sourceProtocolInfo = sourceProtocolInfo
            }
            if let sinkProtocolInfo = property.sinkProtocolInfo {
                result.sinkProtocolInfo = sinkProtocolInfo
            }
            if let currentConnectionIDs = property.currentConnectionIDs {
                result.currentConnectionIDs = currentConnectionIDs
            }
            return result
        }
    }

    var stateSubject: AnyPublisher<State, Never> {
        subscribedEventPublisher
            .compactMap { [weak self] in
                guard let self else { return nil }

                return try? self.state(xml: $0)
            }
            .eraseToAnyPublisher()
    }
}
