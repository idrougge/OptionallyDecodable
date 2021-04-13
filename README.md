# OptionallyDecodable

OptionallyDecodable turns decoding failures into optionals instead of errors.

Swift's `Codable` system allows for simple, declarative coding of objects into popular serialisation formats like JSON and back.

However, when communicating with many REST APIs, the JSON response objects may not be as strict as Swift prefers them to be, at which point `JSONDecoder` gives up and throws an error. For nested objects, this error propagates to the top level object, resulting in failure to decode a large object because a single element in an object nested several levels deep was unexpectedly set to `null` or a hitherto unknown enum value. This applies even if you declare that property as optional, since only a JSON `null` or the absence of said value will be decoded as `nil`.

OptionallyDecodable lets you annotate properties where you are unsure of their exact makeup either because of lacking documentation, erroneous implementations or for handling unexpected changes in the API contract.

# Usage

Simply annotate a property at the "failure point" you are comfortable with, e.g. in some cases you want to just make a single enum value optional if an unknown case was sent, whereas in some cases you may want to throw away a much bigger part of the response because it doesn't satisfy your requirements because of an over-eager endpoint that returns objects in an incomplete state. 

Given a JSON response such as: 
```json
{
    "code": "OK",
    "result": {
        "text": "abc",
        "number": 123
    }
}
```

you may want to decode this into a structure such as:
```swift
enum Code: String, Decodable { case success = "OK", failure = "FAIL" }

struct Result: Decodable {
    let text: String
    let number: Int
}

struct Response: Decodable {
    let code: Code
    let result: Result
}
```

If, for some reason, the API response suddenly leaves out either the `text` or `number` fields, both the `Result` object and the entire `Response` object will fail to decode. By annotating the `result` property with `@OptionallyDecodable` and changing it to be an optional `var`, its failure to decode will not affect the decoding of the entire `Response` object.

Likewise, if it turns out that the backend, perhaps because of an erroneous microservice somewhere, sometimes sends the `number` as a string instead of as a number, you may make it optional and decorate it with `@OptionallyDecodable`.

The same goes for enums, where the full range of possible return codes was not known when the enum was declared. If declared as `@OptionallyDecodable`, `code` will silently turn into `nil` (or `.none`) instead of throwing.

# Installation

## Using Swift Package Manager
In Xcode, choose File → Swift Packages → Add Package Dependency and paste a link to this repo.

##  Without Swift Package Manager
Simply copy `OptionallyDecodable.swift` into your project.
