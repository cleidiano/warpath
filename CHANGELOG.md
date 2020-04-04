# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][unreleased]

### Added

### Fixed
- Fix regression with wildcard followed by a outbound index query.
     Ex. `Warpath.query([["a"], ["b", "c"]], "$.*[1]") => {:ok, ["c"]}`

### Changed

## [0.2.0] - 2020-03-30
This realease put a effort to become compatible as possible with the concensus implementaion of others json path library, to see a comparisions between libraries, visit [json-path-comparison/](https://cburgmer.github.io/json-path-comparison/).

### Added

- Add CHANGELOG.md file.
- Add support for double quoted key, ex. `$["my key"]`.
- Add support to query with negative index, ex. `$[-1]`.
- Add support to query using union property, like `$['one', 'two', 'three']`.  
- Add support for Unicode property, ex. `$.🌢`.
- Add support for bracket notation on filter expression, ex. `$[?(@['key']==42)]`.
- Add support for unquote dash key, ex. `$.dash-key`.

### Fixed
- Fix slice operation on object, now empty list is returned.
- Fix slice operation with negative start index.
- Fix slice operation force user to supplier index, these are valid queries now ex. `$[:]`, `$[::]`.
- Fix slice operation with Zero length, now empty list is returned, ex. `$[0:0]`.
- Fix recursive descent using index, when root document is a list, include it self for index extraction. 
- Fix query using wildcard, won't include `nil` for non existent leaf, ex. `$[*].a` only include a value when `a` exist on object.
 

### Changed
- Update jason dependency from `1.1.2` to `1.2.0`.
- Flatten query that have previous fragment other then `root` and end with a wildcard operator, ex. `$.bar.*`.
- Unwrap output of query that the only possible result is as scalar value, ex. `Warpath.query!([1, 2, 3], "$[0]")` will return `1` instead of `[1]`.


[unreleased]: https://github.com/Cleidiano/warpath/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Cleidiano/warpath/compare/v0.1.0...v0.2.0
[0.1.1]: https://github.com/Cleidiano/warpath/compare/v0.1.0...v0.1.1
[0.0.2]: https://github.com/Cleidiano/warpath/compare/v0.0.2...v0.1.0
[0.0.1]: https://github.com/Cleidiano/warpath/compare/v0.0.1...v0.0.2
