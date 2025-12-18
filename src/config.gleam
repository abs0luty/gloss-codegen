import gleam/dict.{type Dict}
import gleam/option.{type Option, None}

pub type FieldNamingStrategy {
  SnakeCase
  CamelCase
}

pub type DecodeAbsentFieldAs {
  DecodeAbsentFieldAsError
  DecodeAbsentFieldAsNone
}

pub type FieldConfig {
  FieldConfig(
    maybe_absent: Option(Bool),
    must_exist: Option(Bool),
    rename: Option(String),
    encode_as: List(String),
  )
}

pub type TypeConfig {
  TypeConfig(
    generate_encoder: Option(Bool),
    generate_decoder: Option(Bool),
    field_naming_strategy: Option(FieldNamingStrategy),
    type_tag: Option(String),
    no_type_tag: Option(Bool),
    fields: Dict(String, FieldConfig),
  )
}

pub type ModuleConfig {
  ModuleConfig(
    field_naming_strategy: Option(FieldNamingStrategy),
    decode_absent_field_as: Option(DecodeAbsentFieldAs),
    types: Dict(String, TypeConfig),
  )
}

pub type OutputConfig {
  OutputConfig(directory: String, file_suffix: String)
}

pub type Config {
  Config(
    field_naming_strategy: FieldNamingStrategy,
    decode_absent_field_as: DecodeAbsentFieldAs,
    output: OutputConfig,
    modules: Dict(String, ModuleConfig),
  )
}

pub fn default_config() -> Config {
  Config(
    field_naming_strategy: SnakeCase,
    decode_absent_field_as: DecodeAbsentFieldAsNone,
    output: OutputConfig(directory: ".", file_suffix: "_json"),
    modules: dict.new(),
  )
}

pub fn default_field_config() -> FieldConfig {
  FieldConfig(maybe_absent: None, must_exist: None, rename: None, encode_as: [])
}

pub fn default_type_config() -> TypeConfig {
  TypeConfig(
    generate_encoder: None,
    generate_decoder: None,
    field_naming_strategy: None,
    type_tag: None,
    no_type_tag: None,
    fields: dict.new(),
  )
}

pub fn default_module_config() -> ModuleConfig {
  ModuleConfig(
    field_naming_strategy: None,
    decode_absent_field_as: None,
    types: dict.new(),
  )
}
