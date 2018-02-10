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
        let path: PathTemplate = ":scheme://:hostname/:path*.swift"
        let params = path.extract("https://www.github.com/gjeck/PathTemplate.swift")
        XCTAssertEqual(params, ["scheme": "https", "hostname": "www.github.com", "path": "gjeck/PathTemplate"])
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
        ("testInitializingWithDifferentOptionsResultsInInequality", testInitializingWithDifferentOptionsResultsInInequality)
    ]
}

