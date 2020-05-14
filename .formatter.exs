# Used by "mix format"
[
  inputs:
    Enum.flat_map(["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"], &Path.wildcard(&1)) --
      ["test/warpath/tokenizer_test.exs"],
  locals_without_parens: [
    assert_tokens: 2,
    assert_parse: 2,
    assert_parse: 3,
    assert_parse_error: 2
  ],
  import_deps: [:stream_data]
]
