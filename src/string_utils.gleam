import gleam/list
import gleam/string

pub fn to_camel_case(input: String) -> String {
  input
  |> string.split("_")
  |> list.index_map(fn(part, index) {
    case index {
      0 -> part
      _ -> string.capitalise(part)
    }
  })
  |> string.join("")
}

pub fn to_snake_case(input: String) -> String {
  input
  |> string.to_graphemes
  |> list.index_fold([], fn(acc, char, index) {
    case is_uppercase(char) {
      True if index == 0 -> list.append(acc, [string.lowercase(char)])
      True -> list.append(acc, ["_", string.lowercase(char)])
      False -> list.append(acc, [char])
    }
  })
  |> string.join("")
}

fn is_uppercase(char: String) -> Bool {
  char != string.lowercase(char)
}
