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

extension Options: Equatable {
    public static func == (lhs: Options, rhs: Options) -> Bool {
        return lhs.isCaseSensitive == rhs.isCaseSensitive &&
            lhs.isStrict == rhs.isStrict &&
            lhs.isMatchEnd == rhs.isMatchEnd &&
            lhs.delimiter == rhs.delimiter &&
            lhs.endsWith == rhs.endsWith &&
            lhs.delimiters == rhs.delimiters
    }
}

extension Options: Hashable {
    public var hashValue: Int {
        return isCaseSensitive.hashValue ^ isStrict.hashValue ^ isMatchEnd.hashValue ^ delimiter.hashValue ^ delimiters.hashValue
    }
}

func == <T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return lhs == rhs
    case (.none, .none):
        return true
    default:
        return false
    }
}