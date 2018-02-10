# PathTemplate
Swift implementation of templated paths. Inspired by [path-to-regexp](https://github.com/pillarjs/path-to-regexp) and [URITemplate.swift](https://github.com/kylef/URITemplate.swift).

## Installation

#### Swift Package Manager:
Append the following to your `Package.swift` `dependencies: []`
```swift
.package(url: "https://github.com/gjeck/PathTemplate.swift.git")
```

## Basic Usage
A `PathTemplate` is useful for working on structured `String` data like URLs.

#### Expanding a path template
```swift
let template: PathTemplate = "/user/:id"
template.expand(["id": 123])
=> "/user/123"
```

#### Determine the parameters in a template
```swift
let template: PathTemplate = "https://api.github.com/repos/:owner/:repo/"
template.parameterNames
=> ["owner", "repo"]
```

#### Extract the parameters used in a given path
```swift
let template: PathTemplate = "/album/:albumId/artist/:artistId"
template.extract("/album/123/artist/456")
=> ["albumId": "123", "artistId": "456"]
```

## Parameter Modifiers
Named parameters are defined by prefixing a colon to a segment of word characters `[A-Za-z0-9_]` like `:user`.
Additional modifiers can be suffixed for different meaning:
1. `?` -> the parameter is optional
2. `*` -> zero or more parameters
3. `+` -> one or more parameters

## Advanced Usage

#### Enforcing case sensitive matching
```swift
let template = PathTemplate("/User/:id", Options(isCaseSensitive: true))
template.extract("/user/123") // Note that "user" has a lowercase "u"
=> [] 
```

#### Accessing the underlying path regular expression
```swift
let template: PathTemplate = "/user/:id"
template.regex
=> <NSRegularExpression: 0x102745860> ^\/user\/([^\/]+?)(?:\/)?$
```
