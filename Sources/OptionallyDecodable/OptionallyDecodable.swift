//
//  OptionallyDecodable.swift
//  OptionallyDecodable
//
//  Created by Iggy Drougge on 2020-09-29.
//

/// Decodes a value when possible, otherwise yielding `nil`, for more resilient handling of JSON with unexpected shapes such as missing fields or incorrect types. Normally, this would throw a `DecodingError`, aborting the decoding process even of the parent object.
@propertyWrapper public struct OptionallyDecodable<Wrapped: Decodable> {
    public let wrappedValue: Wrapped?
    
    public init(wrappedValue: Wrapped?) {
        self.wrappedValue = wrappedValue
    }
}

extension OptionallyDecodable: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        wrappedValue = try? container?.decode(Wrapped.self)
    }
}

/// We need this protocol to circumvent how the Swift compiler currently handles non-existing fields for property wrappers, always failing when there is no matching key.
public protocol NullableCodable {
    associatedtype Wrapped: Decodable, ExpressibleByNilLiteral
    var wrappedValue: Wrapped { get }
    init(wrappedValue: Wrapped)
}

extension OptionallyDecodable: NullableCodable {}

extension KeyedDecodingContainer {
    /// Necessary for handling non-existing fields, due to how Swift compiler currently synthesises decoders for property wrappers, always failing when there is no matching key.
    public func decode<T: NullableCodable>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        let decoded = try self.decodeIfPresent(T.self, forKey: key) ?? T(wrappedValue: nil)
        return decoded
    }
}

extension OptionallyDecodable: Encodable where Wrapped: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension OptionallyDecodable: Equatable where Wrapped: Equatable {}

extension OptionallyDecodable: Hashable where Wrapped: Hashable {}

#if swift(>=5.5)
extension OptionallyDecodable: Sendable where Wrapped: Sendable {}
#endif
