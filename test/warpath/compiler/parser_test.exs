defmodule Warpath.Compiler.Parser do
  use ExUnit.Case, async: true

  def assert_parse(tokens, output, type \\ :ok) do
    assert :warpath_parser.parse(tokens) == {type, output}
  end

  defp tokenize!(string) do
    string
    |> String.to_charlist()
    |> :warpath_tokenizer.string()
    |> case do
      {:ok, tokens, _} ->
        tokens

      errors ->
        raise inspect(errors)
    end
  end

  @root_expression {:root, "$"}

  test "root expression" do
    assert_parse tokenize!("$"), [@root_expression]
  end

  test "array indexes" do
    one_index = [@root_expression, {:array_indexes, [{:index_access, 1}]}]
    two_indexes = [@root_expression, {:array_indexes, [{:index_access, 1}, {:index_access, 2}]}]

    assert_parse tokenize!("$[1]"), one_index
    assert_parse tokenize!("$.[1]"), one_index

    assert_parse tokenize!("$[1,2]"), two_indexes
    assert_parse tokenize!("$.[1,2]"), two_indexes
  end

  test "wildcard" do
    assert_parse tokenize!("$.*"), [@root_expression, {:wildcard, :*}]

    {:error, {_, :warpath_parser, message}} =
      "*"
      |> tokenize!()
      |> :warpath_parser.parse()

    assert List.to_string(message) == ~S(syntax error before: <<"*">>)
  end

  describe "slice" do
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
      error = {1, :warpath_parser, 'slice step should be greater than zero.'}

      assert_parse tokenize!("$[::-2]"), error, :error
      assert_parse tokenize!("$.[::-2]"), error, :error
    end

    test "with step zero" do
      error = {1, :warpath_parser, 'slice step should be greater than zero.'}

      assert_parse tokenize!("$[::0]"), error, :error
      assert_parse tokenize!("$.[::0]"), error, :error
    end

    test "with to many arguments" do
      error =
        {1, :warpath_parser,
         'to many params found for slice operation, the valid syntax is [start_index:end_index:step]'}

      assert_parse tokenize!("$[::1:]"), error, :error
      assert_parse tokenize!("$.[::1:]"), error, :error
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
      {_, {_Line, _Module, message}} =
        "$[a, b]"
        |> tokenize!()
        |> :warpath_parser.parse()

      assert List.to_string(message) == ~S(syntax error before: <<"a">>)
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
      {_, {_Line, _Module, message}} =
        ~S($."quoted word")
        |> tokenize!()
        |> :warpath_parser.parse()

      assert List.to_string(message) == ~S(syntax error before: <<"quoted word">>)
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

    test "bracket notation identifier lookup in criteria on comparison expression" do
      filter_expression = [
        @root_expression,
        {:filter, {:<, [{:property, "children"}, 2]}}
      ]

      assert_parse tokenize!("$[?( @['children'] < 2)]"), filter_expression
      assert_parse tokenize!("$.[?( @['children'] < 2)]"), filter_expression
    end

    test "union identifier expression lookup should raise syntax error" do
      {:error, {_, _, message}} =
        "$[?( @['one','two'] > 0)]"
        |> tokenize!()
        |> :warpath_parser.parse()

      assert List.to_string(message) == "union expression not supported in filter expression"
    end

    test "union index expression lookup should raise syntax error" do
      {:error, {_, _, message}} =
        "$[?( @[1, 2] > 0)]"
        |> tokenize!()
        |> :warpath_parser.parse()

      assert List.to_string(message) == "union expression not supported in filter expression"
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
      {:error, {_line, _module, message}} =
        "$[?( unmaped_fun(@.children) )]"
        |> tokenize!()
        |> :warpath_parser.parse()

      assert List.to_string(message) == "forbidden function 'unmaped_fun'"
    end
  end
end
