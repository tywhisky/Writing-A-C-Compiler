defmodule MyCompiler do
  def main(args) do
    {_opts, files, _} =
      OptionParser.parse(args,
        switches: [lex: :boolean],
        aliases: []
      )

    files
    |> Enum.each(fn path ->
      path
      |> File.read!()
      |> MyCompiler.Lexer.tokenize()
    end)
  end
end
