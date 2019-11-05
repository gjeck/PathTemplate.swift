import Foundation

/// A data structure to represent a path template
public struct PathTemplate: CustomStringConvertible, ExpressibleByStringLiteral {
    /// The underlying path template
    public let template: String
    /// The regular expression generated from the path
    public let regex: NSRegularExpression?
    // The options used to generate the regular expression
    public let options: Options
    /// The names of the template parameters
    public let parameterNames: [String]

    /// Creates a template from the given string pattern and options
    ///
    /// - Parameter template: the pattern string
    /// - Parameter options: the characteristics to apply on the pattern
    public init(_ template: String, options: Options = .init()) {
        self.template = template
        self.options = options
        let factory = OrderedPathRegexFactory()
        (self.regex, self.keys) = factory.make(template, options: options)
        self.toPathMethod = factory.compile(template, options: options)
        self.parameterNames = keys.map { $0.name }
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
    /// - Parameter encode: an optional encoding strategy for the expansion
    /// - Returns: the expanded path if successful
    public func expand(_ params: [String: Any], encode: ((String) -> String)? = nil) -> String? {
        return try? toPathMethod(params, encode)
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
            } else if key.isOptional {
                result[key.name] = ""
            }
        }
        return result
    }

    private let keys: [Token]
    private let toPathMethod: ([String: Any], ((String) -> String)?) throws -> String
}

// MARK: - PathTemplate: Equatable
extension PathTemplate: Equatable {
    public static func == (lhs: PathTemplate, rhs: PathTemplate) -> Bool {
        return lhs.template == rhs.template && lhs.options == rhs.options
    }
}

// MARK: - PathTemplate: Hashable
extension PathTemplate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(template)
        hasher.combine(options)
    }
}

// MARK: - PathTemplate.Options
extension PathTemplate {
    /// Options for path template generation
    public struct Options {
        let isCaseSensitive: Bool
        let isStrict: Bool
        let isMatchEnd: Bool
        let delimiter: String
        let endsWith: [String]?
        let delimiters: String
        
        /// Initializes an Options
        ///
        /// - Parameters:
        ///     - isCaseSensitive: Determines if the path is case sensitive. Defaults to `false`
        ///     - isStrict: Determines if a trailing delimeter is optional. Defaults to `false`
        ///     - isMatchEnd: Determines if matches occur at the end. Defaults to `true`
        ///     - delimiter: The default delimiter for segments. Defaults to `"/"`
        ///     - endsWith: Optional character, or list of characters, to treat as "end" characters. Defaults to `nil`
        ///     - delimiters: List of characters to consider delimiters when parsing. Defaults to `"./"`
        public init(isCaseSensitive: Bool = false,
                    isStrict: Bool = false,
                    isMatchEnd: Bool = true,
                    delimiter: String = "/",
                    endsWith: [String]? = nil,
                    delimiters: String = "./") {
            self.isCaseSensitive = isCaseSensitive
            self.isStrict = isStrict
            self.isMatchEnd = isMatchEnd
            self.delimiter = delimiter
            self.endsWith = endsWith
            self.delimiters = delimiters
        }
    }
}

// MARK: - PathTemplate.Options: Equatable
extension PathTemplate.Options: Equatable, Hashable {
    public static func == (lhs: PathTemplate.Options, rhs: PathTemplate.Options) -> Bool {
        return lhs.isCaseSensitive == rhs.isCaseSensitive &&
            lhs.isStrict == rhs.isStrict &&
            lhs.isMatchEnd == rhs.isMatchEnd &&
            lhs.delimiter == rhs.delimiter &&
            lhs.endsWith == rhs.endsWith &&
            lhs.delimiters == rhs.delimiters
    }
}

// MARK: - Private Extensions
private extension Array {
    subscript (safe index: Index) -> Element? {
        return 0 <= index && index < count ? self[index] : nil
    }
}
