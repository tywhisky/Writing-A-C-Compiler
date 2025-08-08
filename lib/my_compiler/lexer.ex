defmodule MyCompiler.Lexer do
  @moduledoc false

  @type token_type ::
          :identifier
          | :keyword
          | :constant
          | :parenthesis
          | :brace
          | :semicolon

  @type position :: %{line: pos_integer(), column: pos_integer()}

  @type token ::
          {token_type(), String.t()}
          | {token_type(), String.t(), position()}

  @spec tokenize(String.t()) :: [token()]
  def tokenize(source) do
    IO.inspect(source, label: "Tokenizing source")

    source
    |> handle_comments()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      line
      # TODO: Optimize the tab error line display
      |> String.replace("\t", " ", global: true)
      |> String.split("", trim: true)
      |> Enum.with_index(1)
      |> Enum.map(fn {char, column_number} -> {char, line_number, column_number} end)
    end)
    |> tokenize("", [])
    |> IO.inspect(label: "Tokenized Result")
  end

  def tokenize([], "", result), do: Enum.reverse(result)
  # TODO: Optimize the location of error line and column number
  def tokenize([], acc, result), do: Enum.reverse([match_token(acc, -1, -1) | result])

  def tokenize([{char, line, column} | rest], "", result) when char in ["(", ")"] do
    tokenize(rest, "", [{:parenthesis, char, %{line: line, column: column}} | result])
  end

  def tokenize([{char, line, column} | rest], acc, result) when char in ["(", ")"] do
    tokenize(rest, "", [
      {:parenthesis, char, %{line: line, column: column}},
      match_token(acc, line, column) | result
    ])
  end

  def tokenize([{char, line, column} | rest], "", result) when char in ["{", "}"] do
    tokenize(rest, "", [{:brace, char, %{line: line, column: column}} | result])
  end

  def tokenize([{char, line, column} | rest], acc, result) when char in ["{", "}"] do
    tokenize(rest, "", [
      {:brace, char, %{line: line, column: column}},
      match_token(acc, line, column) | result
    ])
  end

  def tokenize([{";", line, column} | rest], "", result) do
    tokenize(rest, "", [{:semicolon, ";", %{line: line, column: column}} | result])
  end

  def tokenize([{";", line, column} | rest], acc, result) do
    tokenize(rest, "", [
      {:semicolon, ";", %{line: line, column: column}},
      match_token(acc, line, column) | result
    ])
  end

  def tokenize([{" ", _line, _column} | rest], "", result), do: tokenize(rest, "", result)

  def tokenize([{" ", line, column} | rest], acc, result) do
    tokenize(rest, "", [match_token(acc, line, column) | result])
  end

  def tokenize([{char, _line, _column} | rest], acc, result),
    do: tokenize(rest, acc <> char, result)

  defp match_token(token, line, column) do
    cond do
      "int" == token ->
        {:keyword, token, %{line: line, column: column}}

      "void" == token ->
        {:keyword, token, %{line: line, column: column}}

      "return" == token ->
        {:keyword, token, %{line: line, column: column}}

      Regex.match?(~r/^\d+$/, token) ->
        {:constant, token, %{line: line, column: column}}

      Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*/, token) ->
        {:identifier, token, %{line: line, column: column}}

      true ->
        raise "Unknown token: #{token} at line #{line}, column #{column}"
        System.halt(0)
    end
  end

  defp handle_comments(source) do
    source =
      Regex.replace(~r{/\*.*?\*/}s, source, fn comment ->
        comment
        |> String.graphemes()
        |> Enum.map(fn
          "\n" -> "\n"
          _ -> " "
        end)
        |> Enum.join()
      end)

    Regex.replace(~r{//[^\n]*}, source, fn comment ->
      String.duplicate(" ", String.length(comment))
    end)
  end
end
