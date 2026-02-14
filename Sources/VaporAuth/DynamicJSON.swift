import Foundation
import Vapor

// A dynamic JSON value that can represent any valid JSON.
public enum DynamicJSON: Sendable, Equatable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([DynamicJSON])
    case object([String: DynamicJSON])
}

extension DynamicJSON: Codable {
    public init(from decoder: any Decoder) throws {
        if let container = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            var dict: [String: DynamicJSON] = [:]
            for key in container.allKeys {
                dict[key.stringValue] = try container.decode(DynamicJSON.self, forKey: key)
            }
            self = .object(dict)
            return
        }

        if var arrayContainer = try? decoder.unkeyedContainer() {
            var arr: [DynamicJSON] = []
            while !arrayContainer.isAtEnd {
                let value = try arrayContainer.decode(DynamicJSON.self)
                arr.append(value)
            }
            self = .array(arr)
            return
        }

        let single = try decoder.singleValueContainer()
        if single.decodeNil() {
            self = .null
        } else if let b = try? single.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? single.decode(Int.self) {
            self = .integer(i)
        } else if let d = try? single.decode(Double.self) {
            self = .double(d)
        } else if let s = try? single.decode(String.self) {
            self = .string(s)
        } else {
            throw DecodingError.dataCorruptedError(in: single, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .object(let dict):
            var container = encoder.container(keyedBy: DynamicCodingKeys.self)
            for (k, v) in dict {
                try container.encode(v, forKey: DynamicCodingKeys(stringValue: k)!)
            }
        case .array(let arr):
            var container = encoder.unkeyedContainer()
            for v in arr { try container.encode(v) }
        case .string(let s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        case .integer(let i):
            var container = encoder.singleValueContainer()
            try container.encode(i)
        case .double(let d):
            var container = encoder.singleValueContainer()
            try container.encode(d)
        case .bool(let b):
            var container = encoder.singleValueContainer()
            try container.encode(b)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

private struct DynamicCodingKeys: CodingKey, Sendable {
    var stringValue: String
    var intValue: Int?
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
}

extension DynamicJSON: Content {}
