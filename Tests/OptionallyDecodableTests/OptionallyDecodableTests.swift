import XCTest
@testable import OptionallyDecodable

private struct Inner: Codable, Equatable {
    let string: String
    let number: Int
}

private struct Outer: Codable, Equatable {
    @OptionallyDecodable
    private(set) var inner: Inner?
}

private struct Outermost: Decodable {
    struct Inside: Decodable {
        let innermost: Inner
    }
    @OptionallyDecodable
    private(set) var inside: Inside?
}

final class OptionallyDecodableTests: XCTestCase {

    func testDecodingEmptyJSON() throws {
        let json = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        XCTAssertNil(decoded.inner)
    }
    
    func testDecodingCorrectJSON() throws {
        let json = #"""
        {
            "inner": {
                "string": "Hej",
                "number": 1
            }
        }
        """#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        XCTAssertNotNil(decoded.inner)
    }
    
    func testDecodingMalformedJSON() throws {
        let json = #"""
        {
            "inner": {
                "string": null,
                "number": 2
            }
        }
        """#.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(Outer.self, from: json),
                         "Nested object should be deserialised as nil instead of throwing.")
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        XCTAssertNil(decoded.inner, "Nested struct should be deserialised as nil.")
    }
    
    func testDecodingMissingFieldInJSON() throws {
        let json = #"""
        {
            "inner": {
                "string": null
            }
        }
        """#.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(Outer.self, from: json),
                         "Nested object should be deserialised as nil instead of throwing.")
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        XCTAssertNil(decoded.inner, "Nested struct should be deserialised as nil.")
    }
    
    func testDecodingNullInJSON() throws {
        let json = #"""
        {
            "inner": null
        }
        """#.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(Outer.self, from: json),
                         "Nested object should be deserialised as nil instead of throwing.")
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        XCTAssertNil(decoded.inner, "Nested struct should be deserialised as nil.")
    }
    
    func testPropagationOfNestedValidValues() throws {
        let json = #"""
        {
            "inside": {
                "innermost": {
                    "string": "a",
                    "number": 1
                }
            }
        }
        """#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outermost.self, from: json)
        XCTAssertNotNil(decoded.inside)
        XCTAssertNotNil(decoded.inside?.innermost)
    }
    
    func testPropagationOfNestedInvalidValues() throws {
        let json = #"""
        {
            "inside": {
                "innermost": {
                    "string": "a"
                }
            }
        }
        """#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outermost.self, from: json)
        XCTAssertNil(decoded.inside, "Nested object should be nil because it contains a mis-shaped object.")
    }
    
    func testDecodingEnum() throws {
        enum Test: String, Decodable {
            case ok = "CODING_OK"
            case bad = "CODING_BAD"
        }
        struct Object: Decodable {
            @OptionallyDecodable
            var value: Test?
        }
        let goodJSON = #"{ "value": "CODING_OK" }"#.data(using: .utf8)!
        let good = try JSONDecoder().decode(Object.self, from: goodJSON)
        XCTAssertEqual(good.value, .ok)
        
        let badJSON = #"{ "value": "NEITHER" }"#.data(using: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(Object.self, from: badJSON),
                         "Invalid enum value should be decoded as nil instead of throwing.")
        let bad = try JSONDecoder().decode(Object.self, from: badJSON)
        XCTAssertNil(bad.value, "Invalid enum value should be decoded as nil.")
    }
    
    func testEncoding() throws {
        let object = Outer(inner: Inner(string: "abc", number: 123))
        _ = try JSONEncoder().encode(object)
    }
    
    func testRoundtrip() throws {
        let json = #"""
        {
            "inner": {
                "string": "abc",
                "number": 123
            }
        }
        """#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        let encoded = try JSONEncoder().encode(decoded)
        let recoded = try JSONDecoder().decode(Outer.self, from: encoded)
        XCTAssertNotNil(recoded.inner,
                        "Object should survive encode/decode roundtrip if correct.")
        XCTAssertEqual(recoded, Outer(inner: Inner(string: "abc", number: 123)))
    }
    
    func testRoundtripOfMalformedJSON() throws {
        let json = #"""
        {
            "inner": {
                "string": null,
                "number": 123
            }
        }
        """#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Outer.self, from: json)
        let encoded = try JSONEncoder().encode(decoded)
        let recoded = try JSONDecoder().decode(Outer.self, from: encoded)
        XCTAssertNil(recoded.inner,
                     "Object should survive encode/decode roundtrip if correct.")
    }
}
