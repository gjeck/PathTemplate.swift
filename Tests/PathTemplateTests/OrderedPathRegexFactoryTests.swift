import XCTest
@testable import PathTemplate

class OrderedPathRegexTests: XCTestCase {
    var factory: OrderedPathRegexFactory!
    
    override func setUp() {
        super.setUp()
        factory = OrderedPathRegexFactory()
    }
    
    func testItHandlesSimplePaths() {
        var (regex, keys) = factory.make("/")
        XCTAssertTrue(keys.isEmpty)
        XCTAssertEqual(regex?.pattern, "^\\/(?:\\/)?$")
        XCTAssertTrue(does(regex: regex, matchOn: "/"))
        XCTAssertFalse(does(regex: regex, matchOn: "cool"))
        
        (regex, keys) = factory.make("/test")
        XCTAssertTrue(keys.isEmpty)
        XCTAssertEqual(regex?.pattern, "^\\/test(?:\\/)?$")
        XCTAssertTrue(does(regex: regex, matchOn: "/test"))
        XCTAssertFalse(does(regex: regex, matchOn: "/test/things"))

        (regex, keys) = factory.make("/TEST/")
        XCTAssertTrue(keys.isEmpty)
        XCTAssertEqual(regex?.pattern, "^\\/TEST\\/(?:\\/)?$")
        XCTAssertTrue(does(regex: regex, matchOn: "/test/"))
        XCTAssertFalse(does(regex: regex, matchOn: "/TEST"))
    }
    
    func testItIgnoresTheSchemeColonInPaths() {
        let (regex, keys) = factory.make("myapp://user/:userId")
        XCTAssertEqual(keys.map { $0.name }, ["userId"])
        XCTAssertTrue(does(regex: regex, matchOn: "myapp://user/123"))
        XCTAssertFalse(does(regex: regex, matchOn: "otherapp://user/123"))
    }
    
    func testItHandlesSimpleNamedParameterPaths() {
        var (regex, keys) = factory.make("/:test")
        XCTAssertEqual(keys.map { $0.name }, ["test"])
        XCTAssertEqual(regex?.pattern, "^\\/([^\\/]+?)(?:\\/)?$")
        
        (regex, keys) = factory.make("/artist/:artistId/album/:albumId")
        XCTAssertEqual(keys.map { $0.name }, ["artistId", "albumId"])
        XCTAssertEqual(regex?.pattern, "^\\/artist\\/([^\\/]+?)\\/album\\/([^\\/]+?)(?:\\/)?$")
        XCTAssertTrue(does(regex: regex, matchOn: "/artist/123/album/123"))
    }
    
    func testItCanEnforceCaseSensitivity() {
        let (regex, _) = factory.make("/Album/:id", options: .init(isCaseSensitive: true))
        XCTAssertTrue(does(regex: regex, matchOn: "/Album/radical"))
        XCTAssertFalse(does(regex: regex, matchOn: "/album/123"))
    }
    
    func testItCanEnfoceStrictMode() {
        let (regex, _) = factory.make("/test/", options: .init(isStrict: true))
        XCTAssertTrue(does(regex: regex, matchOn: "/test/"))
        XCTAssertTrue(does(regex: regex, matchOn: "/TEST/"))
        XCTAssertFalse(does(regex: regex, matchOn: "/test"))
    }
    
    func testItCanEnforceCaseAndStrictModes() {
        let (regex, _) = factory.make("/test/", options: .init(isCaseSensitive: true, isStrict: true))
        XCTAssertTrue(does(regex: regex, matchOn: "/test/"))
        XCTAssertFalse(does(regex: regex, matchOn: "/TEST/"))
        XCTAssertFalse(does(regex: regex, matchOn: "/test"))
    }
    
    func testItCanEnforceMatchEndMode() {
        let (regex, _) = factory.make("/test/", options: .init(isMatchEnd: false))
        XCTAssertTrue(does(regex: regex, matchOn: "/test/things"))
    }
    
    func testItCanUtilizeSimpleInternalRegularExpressions() {
        let (regex, _) = factory.make("/album/pic-(\\d+).png")
        XCTAssertFalse(does(regex: regex, matchOn: "/album/pic-abc.png"))
        XCTAssertTrue(does(regex: regex, matchOn: "/album/pic-123.png"))
    }
    
    func testItCanHandleOptionalNamedParameters() {
        let (regex, _) = factory.make("/:cool/:thing?")
        XCTAssertTrue(does(regex: regex, matchOn: "/wow"))
        XCTAssertTrue(does(regex: regex, matchOn: "/wow/optionals"))
    }
    
    func testItCanMatchZeroOrMoreNamedParameters() {
        let (regex, _) = factory.make("/:maybeLotsOfThings*")
        XCTAssertTrue(does(regex: regex, matchOn: "/"))
        XCTAssertTrue(does(regex: regex, matchOn: "/cool"))
        XCTAssertTrue(does(regex: regex, matchOn: "/cool/wow"))
    }
    
    func testItCanMatchOneOrMoreNamedParameters() {
        let (regex, _) = factory.make("/:atLeastOneThing+")
        XCTAssertFalse(does(regex: regex, matchOn: "/"))
        XCTAssertTrue(does(regex: regex, matchOn: "/cool"))
        XCTAssertTrue(does(regex: regex, matchOn: "/cool/wow"))
    }
    
    func testItCanHandleUnicodeInPath() {
        var (regex, keys) = factory.make("/🤖/:robot")
        XCTAssertEqual(keys.map { $0.name }, ["robot"])
        XCTAssertTrue(does(regex: regex, matchOn: "/🤖/cool"))
        
        (regex, keys) = factory.make("/cool/🤖")
        XCTAssertTrue(does(regex: regex, matchOn: "/cool/🤖"))
    }
    
    func testItCanCompileBackToSimplePath() {
        let toPath = factory.compile("/user/:id")
        let path = try? toPath(["id": 123], nil)
        XCTAssertEqual(path, "/user/123")
    }
    
    func testItCanCompileBackToSimplePathWithUnicode() {
        let toPath = factory.compile("/🤖/:robot")
        let path = try? toPath(["robot": "johnny5"], nil)
        XCTAssertEqual(path, "/🤖/johnny5")
    }
    
    func testItCanCompileBackWithMultipleNamedParameters() {
        let toPath = factory.compile("/artist/:artistId/album/:albumId")
        let path = try? toPath(["artistId": 123, "albumId": 456], nil)
        XCTAssertEqual(path, "/artist/123/album/456")
    }
    
    func testItCanCompileBackWithOneOrMoreParameters() {
        let toPath = factory.compile("/user/:ids+")
        let pathA = try? toPath(["ids": ["123", "456", "789"]], nil)
        let pathB = try? toPath([:], nil)
        XCTAssertEqual(pathA, "/user/123/456/789")
        XCTAssertNil(pathB)
    }
    
    func testItCanCompileBackWithZeroOrMoreParameters() {
        let toPath = factory.compile("/user/:ids*")
        let pathA = try? toPath(["ids": ["123", "456", "789"]], nil)
        let pathB = try? toPath([:], nil)
        XCTAssertEqual(pathA, "/user/123/456/789")
        XCTAssertEqual(pathB, "/user")
    }
    
    private func does(regex: NSRegularExpression?, matchOn input: String) -> Bool {
        let length = input.utf16.count
        return regex?.firstMatch(in: input, options: [], range: NSRange(location: 0, length: length)) != nil
    }
    
    static var allTests = [
        ("testItHandlesSimplePaths", testItHandlesSimplePaths),
        ("testItIgnoresTheSchemeColonInPaths", testItIgnoresTheSchemeColonInPaths),
        ("testItHandlesSimpleNamedParameterPaths", testItHandlesSimpleNamedParameterPaths),
        ("testItCanEnforceCaseSensitivity", testItCanEnforceCaseSensitivity),
        ("testItCanEnfoceStrictMode", testItCanEnfoceStrictMode),
        ("testItCanEnforceMatchEndMode", testItCanEnforceMatchEndMode),
        ("testItCanUtilizeSimpleInternalRegularExpressions", testItCanUtilizeSimpleInternalRegularExpressions),
        ("testItCanHandleOptionalNamedParameters", testItCanHandleOptionalNamedParameters),
        ("testItCanMatchZeroOrMoreNamedParameters", testItCanMatchZeroOrMoreNamedParameters),
        ("testItCanMatchOneOrMoreNamedParameters", testItCanMatchOneOrMoreNamedParameters),
        ("testItCanHandleUnicodeInPath", testItCanHandleUnicodeInPath),
        ("testItCanCompileBackToSimplePath", testItCanCompileBackToSimplePath),
        ("testItCanCompileBackToSimplePathWithUnicode", testItCanCompileBackToSimplePathWithUnicode),
        ("testItCanCompileBackWithMultipleNamedParameters", testItCanCompileBackWithMultipleNamedParameters),
        ("testItCanCompileBackWithOneOrMoreParameters", testItCanCompileBackWithOneOrMoreParameters),
        ("testItCanCompileBackWithZeroOrMoreParameters", testItCanCompileBackWithZeroOrMoreParameters)
    ]
}
