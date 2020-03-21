defmodule Warpath.UnsupportedOperationError do
  defexception [:message]
end

defmodule Warpath.IndexNotFoundError do
  defexception [:message]
end

defmodule Warpath.ExpressionError do
  defexception [:message]
end

defmodule Warpath.TokenizerError do
  defexception [:message]
end

defmodule Warpath.ParserError do
  defexception [:message]
end
