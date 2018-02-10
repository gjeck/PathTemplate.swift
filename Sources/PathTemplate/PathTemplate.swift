import Foundation

public struct PathTemplate: CustomStringConvertible, ExpressibleByStringLiteral {
    /// The underlying path template
    public let template: String
    /// The regular expression generated from the path
    public let regex: NSRegularExpression?
    // The options used to generate the regular expression
    public let options: Options

    public init(_ template: String, options: Options = Options()) {
        self.template = template
        self.options = options
        let factory = OrderedPathRegexFactory()
        (self.regex, self.keys) = factory.make(template, options: options)
        self.toPathMethod = factory.compile(template, options: options)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public var description: String {
        return template
    }

    /// Expand the template using the given named parameters
    ///
    /// - Parameter params: the associated values to the named parameters
    /// - Returns: the expanded path if successful
    public func expand(_ params: [String: Any]) -> String? {
        return try? toPathMethod(params, nil)
    }

    /// Extract the values of the named parameters in a path
    ///
    /// - Parameter path: the path to extract values from
    /// - Returns: a dictionary of the named parameters to the extracted values
    public func extract(_ path: String) -> [String: String] {
        var result = [String: String]()
        
        let length = path.utf16.count
        guard let match = regex?.firstMatch(in: path, options: [], range: NSRange(location: 0, length: length)) else {
            return result
        }
        (1..<match.numberOfRanges).forEach { i in
            guard let key = keys[safe: i - 1] else {
                return
            }
            let range = match.range(at: i)
            if range.location != NSNotFound && range.location + range.length <= length {
                let start = path.utf16.index(path.utf16.startIndex, offsetBy: range.location)
                let end = path.utf16.index(path.utf16.startIndex, offsetBy: range.location + range.length)
                guard let str = String(path.utf16[start..<end]) else {
                    return
                }
                result[key.name] = str
            }
        }
        return result
    }

    private let keys: [Token]
    private let toPathMethod: ([String: Any], ((String) -> String)?) throws -> String
}

extension PathTemplate: Equatable {
    public static func == (lhs: PathTemplate, rhs: PathTemplate) -> Bool {
        return lhs.template == rhs.template && lhs.options == rhs.options
    }
}

extension PathTemplate: Hashable {
    public var hashValue: Int {
        return template.hashValue ^ options.hashValue
    }
}

// MARK: - Private Extensions
private extension Array {
    subscript (safe index: Index) -> Element? {
        return 0 <= index && index < count ? self[index] : nil
    }
}
