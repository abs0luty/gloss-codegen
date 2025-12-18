import glance
import gleam/int
import gleam/result
import glexer/token
import simplifile

pub fn parse_gleam_source_file(path: String) -> Result(glance.Module, String) {
  use content <- result.try(
    simplifile.read(path)
    |> result.map_error(fn(_) { "Failed to read file: " <> path }),
  )

  glance.module(content)
  |> result.map_error(parse_error_to_string)
}

pub fn parse_error_to_string(error: glance.Error) -> String {
  case error {
    glance.UnexpectedEndOfInput -> "unexpected end of input"
    glance.UnexpectedToken(token, position) ->
      "unexpected token: `"
      <> token.to_source(token)
      <> "` at position "
      <> position.byte_offset |> int.to_string
  }
}
