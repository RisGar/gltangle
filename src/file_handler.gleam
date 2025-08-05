import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

fn parse_target(frontmatter: String) -> Option(String) {
  let assert Ok(re) =
    regexp.from_string("^---[\\s\\S]*?tangle:\\s*(.+)[\\s\\S]*?---")

  case regexp.scan(with: re, content: frontmatter) {
    [match, ..] -> {
      case match.submatches {
        [option.Some(path)] -> Some(path)
        _ -> None
      }
    }
    _ -> None
  }
}

fn parse_code_blocks(content: String) -> List(String) {
  let assert Ok(re) =
    regexp.from_string("(```|~~~)[a-zA-Z]*\\n([\\s\\S]*?)\\n\\1")

  regexp.scan(with: re, content: content)
  |> list.map(fn(match) {
    case match.submatches {
      [_, option.Some(code), ..] -> {
        code <> "\n"
      }
      _ -> ""
    }
  })
}

/// Possible errors during file handling
pub type HandleError {
  ParseError
  ReadError
  WriteError
}

pub type HandleResult {
  HandleResult(target: String, blocks: Int)
}

/// Takes in a file path and an optional overriden target path and returns the target path of the tangled file for logging
pub fn handle(
  file: String,
  target: Option(String),
) -> Result(HandleResult, HandleError) {
  let content =
    file
    |> simplifile.read()
    |> result.replace_error(ReadError)
  use content <- result.try(content)

  let target =
    target
    |> option.or(parse_target(content))
    |> option.to_result(ParseError)
  use target <- result.try(target)

  let code_blocks = parse_code_blocks(content)

  case code_blocks |> string.concat() |> simplifile.write(to: target) {
    Ok(Nil) -> Ok(HandleResult(target, list.length(code_blocks)))
    Error(_) -> Error(WriteError)
  }
}
