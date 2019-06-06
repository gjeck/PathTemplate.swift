import Foundation

struct OrderedPathRegexFactory {
    func make(_ path: String,
              options: PathTemplate.Options = .init()) -> (regex: NSRegularExpression?, keys: [Token])  {
        return tokensToRegex(parse(path, options: options), options: options)
    }
    
    func compile(_ path: String, options: PathTemplate.Options = .init()) -> ([String: Any], ((String) -> String)?) throws -> String {
        return tokensToFunction(parse(path, options: options))
    }
    
    func parse(_ input: String, options: PathTemplate.Options = .init()) -> [Any] {
        let length = input.utf16.count
        let matches = NSRegularExpression.pathRegex.matches(in: input, options: [],
                                                            range: NSRange(location: 0, length: length))
        
        var tokens = [Any]()
        var key: Int = 0
        var index: Int = 0
        var path: String = ""
        var pathEscaped = false
        
        matches.forEach { result in
            var results = [String?]()
            (0..<result.numberOfRanges).forEach { i in
                let range = result.range(at: i)
                if range.location != NSNotFound && range.location + range.length <= length {
                    let start = input.utf16.index(input.utf16.startIndex, offsetBy: range.location)
                    let end = input.utf16.index(input.utf16.startIndex, offsetBy: range.location + range.length)
                    guard let str = String(input.utf16[start..<end]) else {
                        return
                    }
                    results.append(str)
                } else {
                    results.append(nil)
                }
            }
            let m = results[0]
            let escaped = results[1]
            let offset = result.range.location
            let s = input.utf16.index(input.utf16.startIndex, offsetBy: index)
            let e = input.utf16.index(input.utf16.startIndex, offsetBy: offset)
            if let str = String(input.utf16[s..<e]) {
                path += str
            }
            index = offset + (m?.count ?? 0)
            
            if let e = escaped {
                path += String(e.utf16[e.utf16.index(e.utf16.startIndex, offsetBy: 1)])
                pathEscaped = true
                return
            }
            
            var prev = ""
            var next: String?
            if  index < length {
                next = String(input.utf16[input.utf16.index(input.startIndex, offsetBy: index)])
            }
            let name = results[2]
            let capture = results[3]
            let group = results[4]
            let modifier = results[5]
            
            if !pathEscaped && !path.isEmpty {
                let k = path.utf16.count - 1
                let charIndex = path.utf16.index(path.utf16.startIndex, offsetBy: k)
                if options.delimiters.utf16.index(of: path.utf16[charIndex]) != nil {
                    prev = String(path[charIndex])
                    path = String(path[path.startIndex..<charIndex])
                }
            }
            
            if !path.utf16.isEmpty {
                tokens.append(path)
                path = ""
                pathEscaped = false
            }
            
            let isPartial = !prev.isEmpty && next != nil && next != prev
            let shouldRepeat = modifier == "+" || modifier == "*"
            let isOptional = modifier == "?" || modifier == "*"
            let delimiter = !prev.isEmpty ? prev : options.delimiter
            let prePattern = capture ?? group
            let pattern = prePattern != nil ? prePattern! : "[^\(delimiter.escaped)]+?"
            
            let token = Token(name: name ?? String(key),
                              prefix: prev,
                              delimiter: String(delimiter),
                              isOptional: isOptional,
                              shouldRepeat: shouldRepeat,
                              isPartial: isPartial,
                              pattern: pattern)
            tokens.append(token)
            
            if name == nil {
                key += 1
            }
            
        }
        
        if !path.isEmpty || index < length {
            if let str = String(input.utf16[input.utf16.index(input.utf16.startIndex, offsetBy: index)..<input.utf16.endIndex]) {
                tokens.append(path + str)
            }
        }
        
        return tokens
    }
    
    func tokensToRegex(_ tokens: [Any],
                       options: PathTemplate.Options = .init()) -> (regex: NSRegularExpression?, keys: [Token]) {
        let delimiter = options.delimiter.escaped
        let endsWith = ((options.endsWith ?? []).map { $0.escaped } + ["$"]).joined(separator: "|")
        var route = ""
        var isEndDelimited = false
        
        var keys = [Token]()
        
        for (index, token) in tokens.enumerated() {
            if let str = token as? String, let last = str.last {
                route += str.escaped
                isEndDelimited = index == tokens.count - 1 && options.delimiters.contains(last)
            } else if let token = token as? Token {
                let prefix = token.prefix.escaped
                let capture = token.shouldRepeat ? "(?:\(token.pattern))(?:\(prefix)(?:\(token.pattern)))*" : token.pattern
                
                keys.append(token)
                
                if token.isOptional {
                    if token.isPartial {
                        route += "\(prefix)(\(capture))?"
                    } else {
                        route += "(?:\(prefix)(\(capture)))?"
                    }
                } else {
                    route += "\(prefix)(\(capture))"
                }
            }
        }
        
        let isMatchEnd = options.isMatchEnd != false
        if isMatchEnd {
            if !options.isStrict {
                route += "(?:\(delimiter))?"
            }
            route += endsWith == "$" ? "$" : "(?=\(endsWith))"
        } else {
            if !options.isStrict {
                route += "(?:\(delimiter)(?=\(endsWith)))?"
            }
            if !isEndDelimited {
                route += "(?=\(delimiter)|\(endsWith))"
            }
        }
        let regexOptions: NSRegularExpression.Options  = options.isCaseSensitive ? [.useUnicodeWordBoundaries]
            : [.useUnicodeWordBoundaries, .caseInsensitive]
        let regex = try? NSRegularExpression(pattern: "^\(route)", options: regexOptions)
        return (regex, keys)
    }
    
    func tokensToFunction(_ tokens: [Any]) -> ([String: Any], ((String) -> String)?) throws -> String {
        var matches = [NSRegularExpression?](repeating: nil, count: tokens.count)
        for (index, token) in tokens.enumerated() {
            if let token = token as? Token {
                matches[index] = try? NSRegularExpression(pattern: "^(?:\(token.pattern))$", options: [])
            }
        }
        
        let function: ([String: Any], ((String) -> String)?) throws -> String = { data, encode in
            var path = ""
            let encodeMethod: (String) -> String = encode ?? String.uriEncoded
            for (index, token) in tokens.enumerated() {
                if let token = token as? String {
                    path += token
                    continue
                }
                
                guard let token = token as? Token else {
                    continue
                }
                
                if let dataArray = data[token.name] as? [String] {
                    if !token.shouldRepeat {
                        throw Error.compile("Expected \(token.name) to not repeat, but got array")
                    }
                    
                    if dataArray.isEmpty {
                        if token.isOptional {
                            continue
                        }
                        throw Error.compile("Expected \(token.name) to not be empty")
                    }
                    
                    for (j, segment) in dataArray.enumerated() {
                        let encodedSegment = encodeMethod(segment)
                        
                        if matches[index]?.firstMatch(in: encodedSegment, options: [], range: NSRange(location: 0, length: encodedSegment.utf16.count)) == nil {
                            throw Error.compile("Expected all \(token.name) to match \(token.pattern)")
                        }
                        
                        path += (j == 0 ? token.prefix : token.delimiter) + encodedSegment
                    }
                    continue
                }
                
                if let value = data[token.name] as? CustomStringConvertible {
                    let segment = String(describing: value)
                    let encodedSegment = encodeMethod(segment)
                    
                    if matches[index]?.firstMatch(in: encodedSegment, options: [], range: NSRange(location: 0, length: encodedSegment.utf16.count)) == nil {
                        throw Error.compile("Expected all \(token.name) to match \(token.pattern)")
                    }
                    
                    path += token.prefix + encodedSegment
                    continue
                }
                
                if token.isOptional {
                    if token.isPartial {
                        path += token.prefix
                    }
                    continue
                }
                
                throw Error.compile("Generic")
            }
            return path
        }
        
        return function
    }
    
    
}

extension OrderedPathRegexFactory {
    enum Error: Swift.Error {
        case compile(String)
    }
}

private extension NSRegularExpression {
    static let pathRegex = try! NSRegularExpression(pattern: """
    (\\\\.)|(?:\\:(\\w+)(?:\\(((?:\\\\.|[^\\\\()])+)\\))?|\\(((?:\\\\.|[^\\\\()])+)\\))([+*?])?
    """, options: [.useUnicodeWordBoundaries])
}

private extension String {
    var escaped: String {
        return NSRegularExpression.escapedPattern(for: self)
    }
    
    static let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    static let unreservedCharset = CharacterSet(charactersIn: unreservedChars)
    
    static func uriEncoded(_ str: String) -> String {
        return str.addingPercentEncoding(withAllowedCharacters: unreservedCharset) ?? str
    }
}
