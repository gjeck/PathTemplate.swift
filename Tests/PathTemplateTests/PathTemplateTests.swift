import XCTest
@testable import PathTemplate

class PathTemplateTests: XCTestCase {
    func testItCanBeInitializedAsAStringLiteral() {
        let path: PathTemplate = "/user/:id"
        XCTAssertEqual(path.template, "/user/:id")
    }
    
    func testItCanBeInitializedAsAStringLiteralWithUnicode() {
        let path: PathTemplate = "/🤖/:robot"
        XCTAssertEqual(path.template, "/🤖/:robot")
    }
    
    func testItIsEquatable() {
        let a: PathTemplate = "/user/:id"
        let b: PathTemplate = "/user/:id"
        XCTAssertTrue(a == b)
    }
    
    func testItComparesDifferentTemplatesCorrectly() {
        let a: PathTemplate = ":scheme://:hostname/"
        let b: PathTemplate = ":scheme://:hostname:path/"
        XCTAssertTrue(a != b)
    }
    
    func testItIsHashable() {
        let a: PathTemplate = "/user/:id"
        let b: PathTemplate = "/user/:id"
        XCTAssertTrue(a.hashValue == b.hashValue)
    }
    
    func testItCanBeDescribed() {
        let path: PathTemplate = "/user/:id"
        XCTAssertEqual(path.description, "/user/:id")
        XCTAssertEqual("\(path)", "/user/:id")
    }
    
    func testItCanExpandSimpleTemplateIntoPath() {
        let path: PathTemplate = "/user/:id"
        let expanded = path.expand(["id": 123])
        XCTAssertEqual(expanded, "/user/123")
    }
    
    func testItCanExtractParametersFromSimplePath() {
        let path: PathTemplate = "/artist/:artistId/album/:albumId"
        let params = path.extract("/artist/123/album/456")
        XCTAssertEqual(params, ["artistId": "123", "albumId": "456"])
    }
    
    func testInitializingWithDifferentOptionsResultsInInequality() {
        let caseSensitivePath = PathTemplate("/User/:id", options: .init(isCaseSensitive: true))
        let caseInsensitivePath = PathTemplate("/User/:id", options: .init(isCaseSensitive: false))
        XCTAssertNotEqual(caseSensitivePath, caseInsensitivePath)
        XCTAssertNotEqual(caseSensitivePath.hashValue, caseInsensitivePath.hashValue)
    }
    
    func testItCanExpandParametersFromComplexPath() {
        let path: PathTemplate = ":scheme://:hostname/:path+.swift"
        let expanded = path.expand(["scheme": "https", "hostname": "www.github.com", "path": ["gjeck", "PathTemplate"]])
        XCTAssertEqual(expanded, "https://www.github.com/gjeck/PathTemplate.swift")
    }
    
    func testItCanExtractFromComplexPath() {
        let path: PathTemplate = ":scheme://:hostname/:path*"
        let paramsA = path.extract("https://www.github.com/gjeck/PathTemplate.swift")
        let paramsB = path.extract("https://www.github.com/")
        XCTAssertEqual(paramsA, ["scheme": "https", "hostname": "www.github.com", "path": "gjeck/PathTemplate.swift"])
        XCTAssertEqual(paramsB, ["scheme": "https", "hostname": "www.github.com"])
    }
    
    func testItCanExpandParametersFromPathWithMultipleRegularExpressions() {
        let path: PathTemplate = ":scheme://:hostname/:path*/(\\d+)/(.*).png"
        let expanded = path.expand(["scheme": "https", "hostname": "www.github.com", "path": "gjeck", "0": 123, "1": "cool"])
        XCTAssertEqual(expanded, "https://www.github.com/gjeck/123/cool.png")
    }
    
    func testItCanExtractParametersFromPathWithMultipleRegularExpressions() {
        let path: PathTemplate = ":scheme://:hostname/:path*/(\\d+)/(.*).png"
        let params = path.extract("https://www.github.com/gjeck/PathTemplate.swift/123/cool.png")
        let expected = [
            "scheme": "https",
            "hostname": "www.github.com",
            "path": "gjeck/PathTemplate.swift",
            "0": "123",
            "1": "cool"
        ]
        XCTAssertEqual(params, expected)
    }
    
    func testItRespectsCaseSensitivityOptionForExtraction() {
        let path = PathTemplate("/User/(\\d+)/settings", options: .init(isCaseSensitive: true))
        let emptyParams = path.extract("/user/123/settings")
        let fullParams = path.extract("/User/123/settings")
        XCTAssertTrue(emptyParams.isEmpty)
        XCTAssertEqual(fullParams, ["0": "123"])
    }
    
    func testItProvidesAListOfParameterNames() {
        let path: PathTemplate = ":scheme://:hostname/:path*/(\\d+)/(.*).png"
        XCTAssertEqual(path.parameterNames, ["scheme", "hostname", "path", "0", "1"])
    }
    
    func testItSupportsOptionalNamedParameters() {
        let path: PathTemplate = ":scheme://:hostname/:path?"
        let expandedWithParam = path.expand(["scheme": "https", "hostname": "github.com", "path": "gjeck"])
        let expandedWithoutParam = path.expand(["scheme": "https", "hostname": "github.com"])
        XCTAssertEqual(expandedWithParam, "https://github.com/gjeck")
        XCTAssertEqual(expandedWithoutParam, "https://github.com")
    }
    
    func testItSupportsZeroOrMoreParameters() {
        let path: PathTemplate = "https://:hostname/:path*"
        let expanded = path.expand(["hostname": "github.com", "path": ["user", "gjeck"]])
        let expandedWithoutParam = path.expand(["hostname": "github.com"])
        XCTAssertEqual(expanded, "https://github.com/user/gjeck")
        XCTAssertEqual(expandedWithoutParam, "https://github.com")
    }
    
    func testItSupportsOneOrMoreParameters() {
        let path: PathTemplate = "https://:hostname/:path+"
        let expanded = path.expand(["hostname": "github.com", "path": ["user", "gjeck"]])
        let expandedWithoutParam = path.expand(["hostname": "github.com"])
        XCTAssertEqual(expanded, "https://github.com/user/gjeck")
        XCTAssertNil(expandedWithoutParam)
    }
    
    func testItSupportsCustomMatchedParameters() {
        let path: PathTemplate = "/image-:imageId(\\d+).png"
        let expanded = path.expand(["imageId": 123])
        let invalid = path.expand(["imageId": "abc"])
        XCTAssertEqual(expanded, "/image-123.png")
        XCTAssertNil(invalid)
    }
    
    func testItSupportsUnnamedParameters() {
        let path: PathTemplate = "/cool/(\\d+)/(.*)"
        let expanded = path.expand(["0": 123, "1": "wow"])
        XCTAssertEqual(path.parameterNames, ["0", "1"])
        XCTAssertEqual(expanded, "/cool/123/wow")
    }
    
    func testItSupportsZeroOrMoreParametersAndCustomMatchedParametersWithSpecificDelimiter() {
        let path: PathTemplate = PathTemplate("mail.:domain*.com/user::id(\\d+)@:site.com",
                                              options: .init(delimiter: "."))
        let expanded = path.expand(["domain": ["github", "internal"], "id": 123, "site": "coolSpot"])
        XCTAssertEqual(path.parameterNames, ["domain", "id", "site"])
        XCTAssertEqual(expanded, "mail.github.internal.com/user:123@coolSpot.com")
    }
    
    func testPathWithUnicodeAndCustomMatchedParametersWork() {
        let path: PathTemplate = ":scheme://:userInfo@:host:port?/🤖/:setting([abc])"
        XCTAssertEqual(path.parameterNames, ["scheme", "userInfo", "host", "port", "setting"])
        let expandedMatch = path.expand(["scheme": "mailto", "userInfo": "me", "host": "github.com", "setting": "c"])
        XCTAssertEqual(expandedMatch, "mailto://me@github.com/🤖/c")
        let expandedNoMatch = path.expand(["scheme": "mailto", "userInfo": "me", "host": "github.com", "setting": "d"])
        XCTAssertNil(expandedNoMatch)
    }
    
    func testItSupportsBasicCustomEncodeStrategy() {
        let path: PathTemplate = "/(user|u)/:id(\\d+)/:name?"
        let expanded = path.expand(["0": "u", "id": 1234, "name": "r0b0t"]) { str in
            return String(str.replacingOccurrences(of: "0", with: "o"))
        }
        XCTAssertEqual(expanded, "/u/1234/robot")
    }
    
    static var allTests = [
        ("testItCanBeInitializedAsAStringLiteral", testItCanBeInitializedAsAStringLiteral),
        ("testItCanBeInitializedAsAStringLiteralWithUnicode", testItCanBeInitializedAsAStringLiteralWithUnicode),
        ("testItIsEquatable", testItIsEquatable),
        ("testItComparesDifferentTemplatesCorrectly", testItComparesDifferentTemplatesCorrectly),
        ("testItIsHashable", testItIsHashable),
        ("testItCanBeDescribed", testItCanBeDescribed),
        ("testItCanExpandSimpleTemplateIntoPath", testItCanExpandSimpleTemplateIntoPath),
        ("testItCanExtractParametersFromSimplePath", testItCanExtractParametersFromSimplePath),
        ("testInitializingWithDifferentOptionsResultsInInequality", testInitializingWithDifferentOptionsResultsInInequality),
        ("testItCanExpandParametersFromComplexPath", testItCanExpandParametersFromComplexPath),
        ("testItCanExtractFromComplexPath", testItCanExtractFromComplexPath),
        ("testItCanExpandParametersFromPathWithMultipleRegularExpressions", testItCanExpandParametersFromPathWithMultipleRegularExpressions),
        ("testItRespectsCaseSensitivityOptionForExtraction", testItRespectsCaseSensitivityOptionForExtraction),
        ("testItProvidesAListOfParameterNames", testItProvidesAListOfParameterNames),
        ("testItSupportsOptionalNamedParameters", testItSupportsOptionalNamedParameters),
        ("testItSupportsZeroOrMoreParameters", testItSupportsZeroOrMoreParameters),
        ("testItSupportsOneOrMoreParameters", testItSupportsOneOrMoreParameters),
        ("testItSupportsCustomMatchedParameters", testItSupportsCustomMatchedParameters),
        ("testItSupportsUnnamedParameters", testItSupportsUnnamedParameters)
    ]
}

