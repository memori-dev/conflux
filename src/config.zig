const builtin = @import("builtin");

pub const port = if (builtin.is_test) 7357 else 8080;
pub const baseUrl = if (builtin.is_test) "http://localhost:7357" else "http://localhost:8080";
