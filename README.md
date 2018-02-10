# PathTemplate
[![Build Status](https://travis-ci.org/gjeck/PathTemplate.swift.svg?branch=master)](https://travis-ci.org/gjeck/PathTemplate.swift)
[![codecov](https://codecov.io/gh/gjeck/PathTemplate.swift/branch/master/graph/badge.svg)](https://codecov.io/gh/gjeck/PathTemplate.swift)

Swift implementation of templated paths. Inspired by [path-to-regexp](https://github.com/pillarjs/path-to-regexp) and [URITemplate.swift](https://github.com/kylef/URITemplate.swift).

## Installation

#### Swift Package Manager:
Append the following to your `Package.swift` `dependencies: []`
```swift
.package(url: "https://github.com/gjeck/PathTemplate.swift.git")
```

## Basic Usage
A `PathTemplate` is useful for working on structured `String` data like URLs.

##### Expanding a path template
```swift
let template: PathTemplate = "/user/:id"
template.expand(["id": 123])
=> "/user/123"
```

##### Determine the parameters in a template
```swift
let template: PathTemplate = "https://api.github.com/repos/:owner/:repo/"
template.parameterNames
=> ["owner", "repo"]
```

##### Extract the parameters used in a given path
```swift
let template: PathTemplate = "/artist/:artistId/album/:albumId"
template.extract("/artist/123/album/456")
=> ["artistId": "123", "albumId": "456"]
```

### Parameter Modifiers
Named parameters are defined by prefixing a colon to a segment of word characters `[A-Za-z0-9_]` like `:user`.
Additional modifiers can be suffixed for different meaning:
1. `?` the parameter is optional
2. `*` zero or more segments
3. `+` one or more segments

##### `?` Optional
```swift
let template: PathTemplate = "https://:hostname/:path?"
template.expand(["hostname": "github.com"])
=> "https://github.com"

template.expand(["hostname": "github.com", "path": "user"])
=> "https://github.com/user"
```

##### `*` Zero or More
```swift
let template: PathTemplate = "https://:hostname/:path*"
template.expand(["hostname": "github.com", "path": ["user", "gjeck"]])
=> "https://github.com/user/gjeck"

template.expand(["hostname": "github.com"])
=> "https://github.com"
```

##### `+` One or More
```swift
let template: PathTemplate = "https://:hostname/:path+"
template.expand(["hostname": "github.com", "path": ["user", "gjeck"]])
=> "https://github.com/user/gjeck"

template.expand(["hostname": "github.com"])
=> nil
```

### Regular Expression Parameters
Parameters can be provided a custom regular expression that overrides the default match. For example, you could enforce matching digits in a path.
```swift
let template: PathTemplate = "/image-:imageId(\\d+).png"
template.expand(["imageId": 123])
=> "/image-123.png"

template.expand(["imageId": "abc"])
=> nil
```

### Unnamed Parameters
It is possible to write an unnamed parameter that only consists of a matching group. It works the same as a named parameter, except it will be numerically indexed.
```swift
let template: PathTemplate = "/cool/(\\d+)/(.*)"
template.parameterNames
=> ["0", "1"]

template.expand(["0": 123, "1": "wow"])
=> "/cool/123/wow"
```

### Advanced Usage

#### Enforcing case sensitive matching
```swift
let template = PathTemplate("/User/:id", options: Options(isCaseSensitive: true))
template.extract("/user/123") // Note that "user" has a lowercase "u"
=> [] 
```

#### Accessing the underlying path regular expression
```swift
let template: PathTemplate = "/user/:id"
template.regex
=> <NSRegularExpression: 0x102745860> ^\/user\/([^\/]+?)(?:\/)?$
```
