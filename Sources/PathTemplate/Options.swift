public struct Options {
    let isCaseSensitive: Bool
    let isStrict: Bool
    let isMatchEnd: Bool
    let delimiter: String
    let endsWith: [String]?
    let delimiters: String
    
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
