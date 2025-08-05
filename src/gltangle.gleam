import argv
import file_handler
import gleam/int
import gleam/io
import gleam/option
import glint

fn override_flag() -> glint.Flag(String) {
  glint.string_flag("override")
  |> glint.flag_help("Overrides the target file")
}

fn version_flag() -> glint.Flag(Bool) {
  glint.bool_flag("version")
  |> glint.flag_default(False)
  |> glint.flag_help("Prints the version number")
}

const version_string = "0.1.0"

fn parse() -> glint.Command(Nil) {
  use <- glint.command_help("Tangle Markdown code blocks to a code file")

  use version <- glint.flag(version_flag())
  use override <- glint.flag(override_flag())

  use _, args, flags <- glint.command()

  let assert Ok(version) = version(flags)

  case version {
    True -> io.println(version_string)
    False -> {
      case args {
        [filename] -> {
          let override = flags |> override() |> option.from_result()

          case file_handler.handle(filename, override) {
            Ok(handler_res) ->
              io.println(
                filename
                <> " has been tangled to "
                <> handler_res.target
                <> " ("
                <> int.to_string(handler_res.blocks)
                <> " blocks).",
              )
            Error(file_handler.ReadError) ->
              io.println_error("error: failed to read input file")
            Error(file_handler.ParseError) ->
              io.println_error("error: failed to parse input file")
            Error(file_handler.WriteError) ->
              io.println_error("error: failed to write target file")
          }
        }
        _ -> {
          io.println_error("error: please provide a filename")
        }
      }
    }
  }
}

/// CLI to tangle markdown file code blocks to a file
pub fn main() -> Nil {
  glint.new()
  |> glint.with_name("gltangle")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: parse())
  |> glint.run(argv.load().arguments)
}
