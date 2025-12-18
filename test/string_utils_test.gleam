import string_utils

pub fn case_conversions_test() {
  assert string_utils.to_snake_case("CamelCase") == "camel_case"
  assert string_utils.to_camel_case("snake_case") == "snakeCase"
}
