import gleam/option.{type Option}

pub type User {
  User(id: String, name: String, email: Option(String), created_at: String)
}

pub type Message {
  TextMessage(content: String, sender: String)
  ImageMessage(url: String, width: Int, height: Int, sender: String)
}
