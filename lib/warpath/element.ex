defmodule Warpath.Element do
  @moduledoc false

  alias __MODULE__
  alias Warpath.Element.Path

  @type t :: %Element{value: any, path: Path.acc()}

  @type path_accumulator :: (Path.token(), Path.acc() -> Path.acc())

  defstruct value: nil, path: nil

  @doc """
    Create a new element struct.

    ## Example
      iex> Warpath.Element.new("Warpath", [{:root, "$"}])
      %Warpath.Element{value: "Warpath", path: [{:root, "$"}]}
  """
  @spec new(any, Path.acc()) :: Element.t()
  def new(value, path) when is_list(path) do
    %Element{value: value, path: path}
  end

  @doc """
    Create element for each item.

    ## Example
      #List
      iex> Warpath.Element.elementify([:a, :b], [])
        [
          %Warpath.Element{value: :a, path: [{:index_access, 0}]},
          %Warpath.Element{value: :b, path: [{:index_access, 1}]}
        ]

      #List
      iex> Warpath.Element.elementify(%{name: "Warpath", category: "Autobots"}, [])
        [
          %Warpath.Element{value: "Autobots", path: [{:property, :category }]},
          %Warpath.Element{value: "Warpath", path: [{:property, :name }]}
        ]
  """
  @spec elementify(map(), Path.acc(), path_accumulator) :: [Element.t()]
  def elementify(enum, relative_path, path_fun \\ &Path.accumulate/2)

  def elementify(list, relative_path, path_fun) when is_list(list) do
    list
    |> Stream.with_index()
    |> Enum.map(fn {item, index} ->
      Element.new(item, path_fun.({:index_access, index}, relative_path))
    end)
  end

  def elementify(map, relative_path, path_fun) when is_map(map) do
    Enum.map(
      map,
      fn {k, v} ->
        key_path = path_fun.({:property, k}, relative_path)
        Element.new(v, key_path)
      end
    )
  end

  @doc """
      Extract the path of given element

      ## Example
        iex> path = [{:root, "$"}]
        ...> element = Warpath.Element.new("Warpath", path)
        ...> Warpath.Element.path(element)
        [{:root, "$"}]
  """
  @spec path(t) :: Path.t()
  def path(%Element{path: path}), do: path

  @doc """
      Extract the value of given element

    ## Example
        iex> element = Warpath.Element.new("Warpath", [{:root, "$"}])
        ...> Warpath.Element.value(element)
        "Warpath"
  """
  @spec value(t) :: any()
  def value(%Element{value: value}), do: value

  @doc """
      Verify if element value is a list.

    ## Example
        iex> element = Warpath.Element.new([], [{:root, "$"}])
        ...> Warpath.Element.value_list?(element)
        true

        iex> element = Warpath.Element.new(:atom, [{:root, "$"}])
        ...> Warpath.Element.value_list?(element)
        false
  """
  @spec value_list?(t) :: boolean()
  def value_list?(%Element{value: value}), do: is_list(value)

  @doc """
      Verify if the element value is a map.

    ## Example
        iex> element = Warpath.Element.new(%{}, [{:root, "$"}])
        ...> Warpath.Element.value_map?(element)
        true

        iex> element = Warpath.Element.new("String", [{:root, "$"}])
        ...> Warpath.Element.value_map?(element)
        false
  """
  @spec value_map?(t) :: boolean()
  def value_map?(%Element{value: value}), do: is_map(value)
end
