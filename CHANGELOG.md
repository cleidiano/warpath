# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][unreleased]

## [0.3.0] - 2020-06-09
This release is a complete new implementation strategy, it relay on elixir protocol to promote extensibility and simplify maintainability.

### Added
 - Safe nil traverse on expression.
 - Add option `:path_tokens` and `:value_path_tokens` to Warpath.query/3, this turn possible to get the token of path produced by Warpath on evaluate a expression.
 - Add support to pass compiled expression to `Warpath.query/3` as a jsonpath selector.
 - Add sigils `~q` that could be used to ensure compilation time guarantee for expression.

### Fixed
- Forbidden negative step on slice operation
- Fix reserved words used as children key lookup, to allow expression like, `$.true`, `$.in`.
- Compute item index for path on evaluate negative index.
  Ex. `Warpath.query(["a", "b"], "$.[-2]", result_type: :value_path) => {:ok, {"a", "$[0]"}}`
- Recursive descendant with filter were applying filter over list only, support for map were added.

     Ex. Given this input:
     ```elixir
          %{
          "id" => 2,
          "more" => [
               %{"id" => 2},
               %{"more" => %{"id" => 2}},
               %{"id" => %{"id" => 2}},
               [%{"id" => 2}]
          ]
          }
     ```
     Given this query selector `$..[?(@.id==2)]`
     - version 0.2.1 -> `[%{"id" => 2}, %{"id" => 2}]`
     - version 0.3.0 -> `[%{"id" => 2}, %{"id" => 2}, %{"id" => 2}, %{"id" => 2}]`

### Changed
- Query with index that out off bounds, now will return empty list,
  Ex. `Warpath.query(["a", "b", "c"], "$.[4]") => {:ok, []}`
- Don't allow quoted identifier using dot notation.
- Do not raise for expression that are not supported, instead return `{:error, reason}`.
- Using index on filter expression in data type that is not a list, result in empty list, ex: `Warpath.query!([%{}, :a, "b"], "$[?(@[0] > 1)]") => []`.


## [0.3.0-rc.3] - 2020-06-06

### Added
- Safe nil traverse on expression.

### Changed
- Do not raise for expression that are not supported, instead return `{:error, reason}`.
- Using index on filter expression in data type that is not a list, result in empty list, ex: `Warpath.query!([%{}, :a, "b"], "$[?(@[0] > 1)]") => []`.

## [0.3.0-rc.2] - 2020-05-25
- Improve performance remove overhead caused by Task.async_stream and Stream module.

## [0.3.0-rc.1] - 2020-05-22
This release is a complete new implementation strategy, it relay on elixir protocol to promote extensibility and simplify maintainability.

### Added
 - Add option `:path_tokens` and `:value_path_tokens` to Warpath.query/3, this turn possible to get the token of path produced by Warpath on evaluate a expression.
 - Add support to pass compiled expression to `Warpath.query/3` as a jsonpath selector.
 - Add sigils `~q` that could be used to ensure compilation time guarantee.

### Fixed
- Forbidden negative step on slice operation
- Fix reserved words used as children key lookup, to allow expression like, `$.true`, `$.in`.
- Compute item index for path on evaluate negative index.
  Ex. `Warpath.query(["a", "b"], "$.[-2]", result_type: :value_path) => {:ok, {"a", "$[0]"}}`
- Recursive descendant with filter were applying filter over list only, support for map were added.
     
     Ex. Given this input:
     ```elixir
          %{
          "id" => 2,
          "more" => [
               %{"id" => 2},
               %{"more" => %{"id" => 2}},
               %{"id" => %{"id" => 2}},
               [%{"id" => 2}]
          ]
          }
     ```
     Given this query selector `$..[?(@.id==2)]`
     - version 0.2.1 -> `[%{"id" => 2}, %{"id" => 2}]`
     - version 0.3.0 -> `[%{"id" => 2}, %{"id" => 2}, %{"id" => 2}, %{"id" => 2}]`

### Changed
- Query with index that out off bounds, now will return empty list,
  Ex. `Warpath.query(["a", "b", "c"], "$.[4]") => {:ok, []}`
- Don't allow quoted identifier using dot notation.

## [0.2.1] - 2020-04-05

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


[unreleased]: https://github.com/Cleidiano/warpath/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/Cleidiano/warpath/compare/v0.2.1...v0.3.0
[0.3.0-rc.3]: https://github.com/Cleidiano/warpath/compare/v0.3.0-rc.2...v0.3.0-rc.3
[0.3.0-rc.2]: https://github.com/Cleidiano/warpath/compare/v0.3.0-rc.1...v0.3.0-rc.2
[0.3.0-rc.1]: https://github.com/Cleidiano/warpath/compare/v0.2.1...v0.3.0-rc.1
[0.2.1]: https://github.com/Cleidiano/warpath/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/Cleidiano/warpath/compare/v0.1.0...v0.2.0
[0.1.1]: https://github.com/Cleidiano/warpath/compare/v0.1.0...v0.1.1
[0.0.2]: https://github.com/Cleidiano/warpath/compare/v0.0.2...v0.1.0
[0.0.1]: https://github.com/Cleidiano/warpath/compare/v0.0.1...v0.0.2
