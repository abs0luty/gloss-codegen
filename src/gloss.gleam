import config_parser
import generator
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import simplifile

fn run() -> Result(Nil, String) {
  io.println("Reading configuration from gloss.toml...")
  use config <- result.try(config_parser.parse_config("gloss.toml"))

  io.println("Generating code for src/ directory...")
  use generated_files <- result.try(generator.generate_for_directory(
    "src",
    config,
  ))

  io.println(
    "Writing "
    <> list.length(generated_files) |> int.to_string
    <> " generated files...",
  )
  use _ <- result.try(write_files(generated_files))

  Ok(Nil)
}

fn write_files(files: List(generator.GeneratedFile)) -> Result(Nil, String) {
  files
  |> list.map(fn(file) {
    io.println("  Writing: " <> file.path)
    simplifile.write(file.path, file.content)
    |> result.map_error(fn(_) { "Failed to write file: " <> file.path })
  })
  |> result.all
  |> result.map(fn(_) { Nil })
}

pub fn main() {
  case run() {
    Ok(_) -> io.println("✓ Code generation completed successfully!")
    Error(err) -> io.println("✗ Error: " <> err)
  }
}
