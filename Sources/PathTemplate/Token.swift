import Foundation

struct Token {
    let name: String
    let prefix: String
    let delimiter: String
    let isOptional: Bool
    let shouldRepeat: Bool
    let isPartial: Bool
    let pattern: String
}
