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
        let path: PathTemplate = "/album/:albumId/artist/:artistId"
        let params = path.extract("/album/123/artist/456")
        XCTAssertEqual(params, ["albumId": "123", "artistId": "456"])
    }
    
    func testInitializingWithDifferentOptionsResultsInInequality() {
        let caseSensitivePath = PathTemplate("/User/:id", options: Options(isCaseSensitive: true))
        let caseInsensitivePath = PathTemplate("/User/:id", options: Options(isCaseSensitive: false))
        XCTAssertNotEqual(caseSensitivePath, caseInsensitivePath)
        XCTAssertNotEqual(caseSensitivePath.hashValue, caseInsensitivePath.hashValue)
    }
    
    func testItCanExpandParametersFromComplexPath() {
        let path: PathTemplate = ":scheme://:hostname/:path.swift"
        let expanded = path.expand(["scheme": "https", "hostname": "www.github.com", "path": "gjeck/PathTemplate"])
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
        let path = PathTemplate("/User/(\\d+)/settings", options: Options(isCaseSensitive: true))
        let emptyParams = path.extract("/user/123/settings")
        let fullParams = path.extract("/User/123/settings")
        XCTAssertTrue(emptyParams.isEmpty)
        XCTAssertEqual(fullParams, ["0": "123"])
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
        ("testItRespectsCaseSensitivityOptionForExtraction", testItRespectsCaseSensitivityOptionForExtraction)
    ]
}

