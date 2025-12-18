import config.{
  type Config, type DecodeAbsentFieldAs, type FieldConfig,
  type FieldNamingStrategy, type ModuleConfig, type OutputConfig,
  type TypeConfig, CamelCase, DecodeAbsentFieldAsError, DecodeAbsentFieldAsNone,
  FieldConfig, ModuleConfig, OutputConfig, SnakeCase, TypeConfig,
}
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile
import tom

pub fn parse_config(path: String) -> Result(Config, String) {
  use content <- result.try(
    simplifile.read(path)
    |> result.map_error(fn(_) { "Failed to read config file: " <> path }),
  )

  use toml <- result.try(
    tom.parse(content)
    |> result.map_error(fn(_) { "Failed to parse TOML: " <> path }),
  )

  parse_config_from_toml(toml)
}

fn parse_config_from_toml(
  toml: dict.Dict(String, tom.Toml),
) -> Result(Config, String) {
  use field_naming_strategy <- result.try(
    parse_field_naming_strategy(toml)
    |> result.map(fn(strategy) { strategy |> option.unwrap(CamelCase) }),
  )
  use decode_absent_field_as <- result.try(
    parse_decode_absent_field_as(toml)
    |> result.map(fn(strategy) {
      strategy |> option.unwrap(DecodeAbsentFieldAsError)
    }),
  )
  use modules <- result.try(parse_modules(toml))
  let output = parse_output_config(toml)

  Ok(config.Config(
    field_naming_strategy:,
    decode_absent_field_as:,
    output:,
    modules:,
  ))
}

fn parse_field_naming_strategy(
  toml: dict.Dict(String, tom.Toml),
) -> Result(Option(FieldNamingStrategy), String) {
  parse_one_of(
    toml,
    "rename_all",
    [
      #("camelCase", CamelCase),
      #("snake_case", SnakeCase),
    ],
    "field naming strategy",
  )
}

fn parse_decode_absent_field_as(
  toml: dict.Dict(String, tom.Toml),
) -> Result(Option(DecodeAbsentFieldAs), String) {
  parse_one_of(
    toml,
    "decode_absent_as",
    [
      #("none", DecodeAbsentFieldAsNone),
      #("error", DecodeAbsentFieldAsError),
    ],
    "absent field decode strategy",
  )
}

fn parse_output_config(toml: dict.Dict(String, tom.Toml)) -> OutputConfig {
  OutputConfig(
    directory: tom.get_string(toml, ["output", "directory"])
      |> result.unwrap("."),
    file_suffix: tom.get_string(toml, ["output", "file_suffix"])
      |> result.unwrap("_gloss"),
  )
}

fn parse_modules(
  toml: dict.Dict(String, tom.Toml),
) -> Result(dict.Dict(String, ModuleConfig), String) {
  case tom.get_table(toml, ["modules"]) {
    Ok(modules_table) -> {
      modules_table
      |> dict.to_list
      |> list.try_map(fn(entry) {
        use module_config <- result.try(
          case tom.get_table(toml, ["modules", entry.0]) {
            Ok(mod_table) -> parse_module_config_from_dict(mod_table)
            Error(_) -> Ok(config.default_module_config())
          },
        )

        Ok(#(entry.0, module_config))
      })
      |> result.map(dict.from_list)
    }
    Error(_) -> Ok(dict.new())
  }
}

fn parse_module_config_from_dict(
  toml: dict.Dict(String, tom.Toml),
) -> Result(ModuleConfig, String) {
  use field_naming_strategy <- result.try(parse_field_naming_strategy(toml))
  use decode_absent_field_as <- result.try(parse_decode_absent_field_as(toml))
  use types <- result.try(parse_types(toml))

  Ok(ModuleConfig(field_naming_strategy:, decode_absent_field_as:, types:))
}

pub fn parse_module_config(
  toml_kv: dict.Dict(String, tom.Toml),
) -> Result(ModuleConfig, String) {
  use field_naming_strategy <- result.try(parse_field_naming_strategy(toml_kv))
  use decode_absent_field_as <- result.try(parse_decode_absent_field_as(toml_kv))
  use types <- result.try(parse_types(toml_kv))

  Ok(ModuleConfig(field_naming_strategy:, decode_absent_field_as:, types:))
}

fn toml_object_to_dict(toml: tom.Toml) -> dict.Dict(String, tom.Toml) {
  case toml {
    tom.InlineTable(table) -> table
    tom.ArrayOfTables(tables) -> {
      case tables {
        [first, ..] -> first
        [] -> dict.new()
      }
    }
    _ -> {
      dict.new()
    }
  }
}

fn parse_types(
  toml: dict.Dict(String, tom.Toml),
) -> Result(dict.Dict(String, TypeConfig), String) {
  case tom.get_table(toml, ["types"]) {
    Ok(types_table) -> {
      types_table
      |> dict.keys
      |> list.try_map(fn(type_name) {
        use type_config <- result.try(
          case tom.get_table(toml, ["types", type_name]) {
            Ok(type_table) -> parse_type_config(type_table)
            Error(_) -> Ok(config.default_type_config())
          },
        )

        Ok(#(type_name, type_config))
      })
      |> result.map(dict.from_list)
    }
    Error(_) -> {
      Ok(dict.new())
    }
  }
}

pub fn parse_type_config(
  toml: dict.Dict(String, tom.Toml),
) -> Result(TypeConfig, String) {
  use field_naming_strategy <- result.try(parse_field_naming_strategy(toml))
  use fields <- result.try(parse_fields(toml))

  Ok(TypeConfig(
    fields:,
    generate_encoder: tom.get_bool(toml, ["generate_encoder"])
      |> option.from_result,
    generate_decoder: tom.get_bool(toml, ["generate_decoder"])
      |> option.from_result,
    field_naming_strategy:,
    type_tag: tom.get_string(toml, ["type_tag"]) |> option.from_result,
    no_type_tag: tom.get_bool(toml, ["no_type_tag"]) |> option.from_result,
  ))
}

fn parse_fields(
  toml: dict.Dict(String, tom.Toml),
) -> Result(dict.Dict(String, FieldConfig), String) {
  case tom.get_table(toml, ["fields"]) {
    Ok(fields_table) -> {
      fields_table
      |> dict.to_list
      |> list.try_map(fn(entry) {
        let toml = toml_object_to_dict(entry.1)
        use field_config <- result.try(parse_field_config(toml))

        Ok(#(entry.0, field_config))
      })
      |> result.map(dict.from_list)
    }
    Error(_) -> Ok(dict.new())
  }
}

fn parse_field_config(
  toml: dict.Dict(String, tom.Toml),
) -> Result(FieldConfig, String) {
  use encode_as <- result.try(
    tom.get_array(toml, ["encode_as"])
    |> option.from_result
    |> option.unwrap([])
    |> list.try_map(fn(object) {
      case object {
        tom.String(string) -> Ok(string)
        _ -> Error("Invalid encode_as value, expected string")
      }
    }),
  )

  Ok(FieldConfig(
    maybe_absent: tom.get_bool(toml, ["maybe_absent"])
      |> option.from_result,
    must_exist: tom.get_bool(toml, ["must_exist"]) |> option.from_result,
    rename: tom.get_string(toml, ["rename"]) |> option.from_result,
    encode_as:,
  ))
}

fn parse_one_of(
  toml: dict.Dict(String, tom.Toml),
  toml_key: String,
  values: List(#(String, e)),
  type_name: String,
) -> Result(Option(e), String) {
  let error = fn(mapping: List(#(String, _)), type_name) {
    "Invalid "
    <> type_name
    <> ": the value is not one of "
    <> string.join(
      mapping
        |> list.map(fn(tuple) { tuple.0 }),
      ", ",
    )
  }

  case tom.get_string(toml, [toml_key]) {
    Ok(value) -> {
      case list.find(values, fn(tuple) { tuple.0 == value }) {
        Ok(#(_, value)) -> Ok(Some(value))
        Error(Nil) -> Error(error(values, type_name))
      }
    }
    Error(tom.NotFound(_)) -> Ok(None)
    Error(tom.WrongType(..)) -> Error(error(values, type_name))
  }
}
