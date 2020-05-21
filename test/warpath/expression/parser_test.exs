defmodule Warpath.Expression.ParserTest do
  use ExUnit.Case, async: true

  import Warpath.Expression.Tokenizer

  alias Warpath.Expression.Parser
  alias Warpath.Expression.ParserError

  @root_expression {:root, "$"}
  @error_message_prefix "Parser error: Invalid token on line 1,"

  def assert_parse(tokens, output, type \\ :ok) do
    assert Parser.parse(tokens) == {type, output}
  end

  def assert_parse_error(tokens, error_message) do
    assert {:error, %ParserError{message: error_message}} == Parser.parse(tokens)
  end

  test "root expression" do
    assert_parse tokenize!("$"), [@root_expression]
  end

  test "array indexes" do
    one_index = [@root_expression, {:indexes, [{:index_access, 1}]}]
    two_indexes = [@root_expression, {:indexes, [{:index_access, 1}, {:index_access, 2}]}]

    assert_parse tokenize!("$[1]"), one_index
    assert_parse tokenize!("$.[1]"), one_index

    assert_parse tokenize!("$[1,2]"), two_indexes
    assert_parse tokenize!("$.[1,2]"), two_indexes
  end

  test "wildcard" do
    assert_parse tokenize!("$.*"), [@root_expression, {:wildcard, :*}]
    assert_parse_error tokenize!("*"), ~s(#{@error_message_prefix} syntax error before: <<"*">>)
  end

  describe "array slice," do
    test "with only one colon supplied" do
      expression = [
        @root_expression,
        {:slice, []}
      ]

      assert_parse tokenize!("$[:]"), expression
      assert_parse tokenize!("$.[:]"), expression
    end

    test "with two colon supplied without indexes" do
      expression = [
        @root_expression,
        {:slice, []}
      ]

      assert_parse tokenize!("$[::]"), expression
      assert_parse tokenize!("$.[::]"), expression
    end

    test "with only start index supplied" do
      expression = [
        @root_expression,
        {:slice, [start_index: 1]}
      ]

      assert_parse tokenize!("$[1:]"), expression
      assert_parse tokenize!("$.[1:]"), expression
    end

    test "with start and end_index supplied" do
      expression = [
        @root_expression,
        {:slice, [start_index: 1, end_index: 3]}
      ]

      assert_parse tokenize!("$[1:3]"), expression
      assert_parse tokenize!("$.[1:3]"), expression
    end

    test "with start end_index and step supplied" do
      expression = [
        @root_expression,
        {:slice, [start_index: 1, end_index: 3, step: 2]}
      ]

      assert_parse tokenize!("$[1:3:2]"), expression
      assert_parse tokenize!("$.[1:3:2]"), expression
    end

    test "with negative step" do
      error_message = "#{@error_message_prefix} slice step should be greater than zero."

      assert_parse_error tokenize!("$[::-2]"), error_message
      assert_parse_error tokenize!("$.[::-2]"), error_message
    end

    test "with step zero" do
      error_message = "#{@error_message_prefix} slice step should be greater than zero."

      assert_parse_error tokenize!("$[::0]"), error_message
      assert_parse_error tokenize!("$.[::0]"), error_message
    end

    test "with to many arguments" do
      error_message =
        "#{@error_message_prefix} to many params found for slice operation," <>
          " the valid syntax is [start_index:end_index:step]"

      assert_parse_error tokenize!("$[::1:]"), error_message
      assert_parse_error tokenize!("$.[::1:]"), error_message
      assert_parse_error tokenize!("$.[::1:1]"), error_message
    end
  end

  describe "union" do
    test "expression with one identifier should have dot identifier instead" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "one"}}
      ]

      assert_parse tokenize!("$['one']"), expression_result
      assert_parse tokenize!("$.['one']"), expression_result
    end

    test "expression when have more then one identifier" do
      expression_result = [
        @root_expression,
        {:union,
         [
           {:dot, {:property, "one"}},
           {:dot, {:property, "two"}}
         ]}
      ]

      assert_parse tokenize!("$['one', 'two']"), expression_result
      assert_parse tokenize!("$.['one', 'two']"), expression_result
    end

    test "atom expression" do
      expression_result = [
        @root_expression,
        {:union,
         [
           {:dot, {:property, :one}},
           {:dot, {:property, :two}}
         ]}
      ]

      assert_parse tokenize!("$[:one, :two]"), expression_result
      assert_parse tokenize!("$.[:one, :two]"), expression_result
    end

    test "error when using unquoted expression" do
      assert_parse_error tokenize!("$[a, b]"),
                         ~s(#{@error_message_prefix} syntax error before: <<"a">>)
    end
  end

  describe "identifier" do
    test "simple" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "simple"}}
      ]

      assert_parse tokenize!("$.simple"), expression_result
    end

    test "simple atom" do
      expression_result = [
        @root_expression,
        {:dot, {:property, :simple}}
      ]

      assert_parse tokenize!("$.:simple"), expression_result
      assert_parse tokenize!(~S($.:"simple")), expression_result
    end

    test "quoted forbidden on dot child expression" do
      assert_parse_error tokenize!(~S($."quoted word")),
                         ~s(#{@error_message_prefix} syntax error before: <<"quoted word">>)
    end
  end

  describe "special identifier" do
    test "integer" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "2"}}
      ]

      assert_parse tokenize!("$.2"), expression_result
    end

    test "in" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "in"}}
      ]

      assert_parse tokenize!("$.in"), expression_result
    end

    test "or" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "or"}}
      ]

      assert_parse tokenize!("$.or"), expression_result
    end

    test "not" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "not"}}
      ]

      assert_parse tokenize!("$.not"), expression_result
    end

    test "and" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "and"}}
      ]

      assert_parse tokenize!("$.and"), expression_result
    end

    test "true" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "true"}}
      ]

      assert_parse tokenize!("$.true"), expression_result
    end

    test "false" do
      expression_result = [
        @root_expression,
        {:dot, {:property, "false"}}
      ]

      assert_parse tokenize!("$.false"), expression_result
    end
  end

  describe "filter expression with" do
    test "boolean literal as criteria" do
      filter_expression = [
        @root_expression,
        {:filter, true}
      ]

      assert_parse tokenize!("$[?(true)]"), filter_expression
      assert_parse tokenize!("$.[?(true)]"), filter_expression
    end

    test "number literal comparison expression as criteria" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [1.0, 2]}}
      ]

      assert_parse tokenize!("$[?( 1.0 < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( 1.0 < 2)]"), filter_expression
    end

    test "identifier lookup in criteria on comparison expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [{:property, "identifier"}, 2]}}
      ]

      assert_parse tokenize!("$[?( @.identifier < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( @.identifier < 2)]"), filter_expression
    end

    test "at operator must be followed by a dot operator on lookup criteria" do
      assert_parse_error tokenize!("$[?( @identifier < 3)]"),
                         ~s(#{@error_message_prefix} syntax error before: <<"identifier">>)
    end

    test "atom_identifier lookup in criteria on comparison expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [{:property, :identifier}, 2]}}
      ]

      assert_parse tokenize!("$[?( @.:identifier < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( @.:identifier < 2)]"), filter_expression
    end

    test "index lookup in criteria on comparison expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [{:index_access, 0}, 2]}}
      ]

      assert_parse tokenize!("$[?( @[0] < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( @[0] < 2)]"), filter_expression
    end

    test "has children predicate as a criteria expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:has_property?, {:property, "children"}}}
      ]

      assert_parse tokenize!("$[?( @['children'] )]"), filter_expression
      assert_parse tokenize!("$[?( @.['children'] )]"), filter_expression

      assert_parse tokenize!("$.[?( @['children'] )]"), filter_expression
      assert_parse tokenize!("$.[?( @.['children'] )]"), filter_expression

      assert_parse tokenize!("$[?( @.children )]"), filter_expression
      assert_parse tokenize!("$.[?( @.children )]"), filter_expression

      assert_parse_error tokenize!("$[?( @identifier )]"),
                         ~s(#{@error_message_prefix} syntax error before: <<"identifier">>)
    end

    test "bracket notation identifier lookup in criteria on comparison expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [{:property, "children"}, 2]}}
      ]

      assert_parse tokenize!("$[?( @['children'] < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( @['children'] < 2)]"), filter_expression
    end

    test "union identifier expression lookup should raise syntax error" do
      tokens = tokenize!("$[?( @['one','two'] > 0)]")
      assert_parse_error tokens, ~s(#{@error_message_prefix} syntax error before: <<",">>)
    end

    test "union index expression lookup should raise not supported error" do
      tokens = tokenize!("$[?( @[1, 2] > 0)]")
      message = "union index expression not supported in filter expression"

      assert_parse_error tokens, "#{@error_message_prefix} #{message}"
    end

    test "safe whitelist funcion call as criteria" do
      safe_functions = [
        :is_atom,
        :is_binary,
        :is_boolean,
        :is_float,
        :is_integer,
        :is_list,
        :is_map,
        :is_nil,
        :is_number,
        :is_tuple
      ]

      Enum.each(safe_functions, fn function ->
        fun_name = Atom.to_string(function)
        children_lookup = {:property, "children"}
        tokens = tokenize!("$[?( #{fun_name}(@.children)  )]")

        assert_parse tokens, [@root_expression, {:filter, {function, children_lookup}}]
      end)
    end

    test "forbidden function call as criteria raise syntax error" do
      tokens = tokenize!("$[?( unmaped_fun(@.children) )]")

      assert_parse_error tokens,
                         "#{@error_message_prefix} forbidden function 'unmaped_fun', " <>
                           "it's only allowed to call whitelist functions: " <>
                           "[is_atom, is_binary, is_boolean, is_float, is_integer, " <>
                           "is_list, is_map, is_nil, is_number, is_tuple]"
    end

    test "and operator" do
      assert_parse tokenize!("$[?(true and true)]"), [
        @root_expression,
        {:filter, {:and, [true, true]}}
      ]
    end

    test "or operator" do
      assert_parse tokenize!("$[?(true or true)]"), [
        @root_expression,
        {:filter, {:or, [true, true]}}
      ]
    end

    test "or operator precedence" do
      assert_parse tokenize!("$[?(true and true or false)]"), [
        @root_expression,
        {:filter, {:or, [{:and, [true, true]}, false]}}
      ]
    end

    test "not operator" do
      assert_parse tokenize!("$[?(not true)]"), [
        @root_expression,
        {:filter, {:not, true}}
      ]

      assert_parse tokenize!("$[?(not false and true)]"), [
        @root_expression,
        {:filter, {:and, [{:not, false}, true]}}
      ]
    end

    test "in operator in criteria with literals in list" do
      assert_parse tokenize!("$[?(@.name in ['Warpath', 0, :warpath, 1.1])]"), [
        @root_expression,
        {:filter, {:in, [{:property, "name"}, ["Warpath", 0, :warpath, 1.1]]}}
      ]
    end

    test "in operator in criteria with item lookup on list" do
      assert_parse tokenize!("$[?(@.name in [@.transformer, @.autobot])]"), [
        @root_expression,
        {:filter,
         {:in,
          [
            {:property, "name"},
            [{:property, "transformer"}, {:property, "autobot"}]
          ]}}
      ]
    end

    test "current children in criteria on comparision expression" do
      assert_parse tokenize!("$[?(@ == 10)]"), [
        @root_expression,
        {:filter, {:==, [:current_node, 10]}}
      ]

      assert_parse tokenize!("$[?(10 == @)]"), [
        @root_expression,
        {:filter, {:==, [10, :current_node]}}
      ]
    end

    test "parenthesis precedence defined" do
      assert_parse tokenize!("$[?(true and (true or false))]"), [
        @root_expression,
        {:filter, {:and, [true, {:or, [true, false]}]}}
      ]
    end
  end

  describe "descendant" do
    test "followed by a dot operator should raise syntax error" do
      error_message =
        "#{@error_message_prefix} operator dot ('.') is not allowed after descendant operator ('..'),\n" <>
          "it must be contracted in a operator (..),\n" <>
          "For example: instead of '$...name' you must write '$..name', that is the right syntax!"

      assert_parse_error tokenize!("$...child"), error_message
    end

    test "string identifier lookup" do
      filter_expression = [
        @root_expression,
        {:scan, {:property, "identifier"}}
      ]

      assert_parse tokenize!("$..identifier"), filter_expression
      assert_parse tokenize!("$..['identifier']"), filter_expression
      assert_parse tokenize!(~S($..["identifier"])), filter_expression
    end

    test "atom identifier lookup" do
      filter_expression = [
        @root_expression,
        {:scan, {:property, :identifier}}
      ]

      assert_parse tokenize!("$..:identifier"), filter_expression
      assert_parse tokenize!("$..[:identifier]"), filter_expression

      assert_parse tokenize!("$..:'identifier'"), filter_expression
      assert_parse tokenize!("$..[:'identifier']"), filter_expression
      assert_parse tokenize!(~S($..:"identifier")), filter_expression
      assert_parse tokenize!(~S($..[:"identifier"])), filter_expression
    end

    test "filter lookup" do
      filter_expression = [
        @root_expression,
        {:scan, {:filter, {:<, [{:property, "identifier"}, 2]}}}
      ]

      assert_parse tokenize!("$..[?( @.identifier < 2)]"), filter_expression
    end

    test "union index expression lookup" do
      tokens = tokenize!("$..[1, 2]")

      assert_parse tokens, [
        @root_expression,
        {:scan, {:indexes, [index_access: 1, index_access: 2]}}
      ]
    end

    test "list with index lookup" do
      tokens = tokenize!("$..[1]")

      assert_parse tokens, [
        @root_expression,
        {:scan, {:indexes, [index_access: 1]}}
      ]
    end

    test "wildcard lookup" do
      expression = [
        @root_expression,
        {:scan, {:wildcard, :*}}
      ]

      assert_parse tokenize!("$..*"), expression
      assert_parse tokenize!("$..[*]"), expression
    end
  end

  describe "parse!/1" do
    test "raise when parser fail" do
      assert_raise ParserError, fn -> Parser.parse!([{:unknown, 1, "unknown"}]) end
    end

    test "sucsessfull parse" do
      assert [{:root, "$"}] == Parser.parse!([{:"$", 1, "$"}])
    end
  end
end
