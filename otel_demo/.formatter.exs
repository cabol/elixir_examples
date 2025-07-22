locals_without_parens = [
  # OtelDemo.OTel
  with_span: 1,
  with_span: 2,
  with_span: 3,
  with_span: 4,
  simple_span: 1,
  simple_span: 2,
  simple_span: 3,
  simple_span: 4
]

[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  line_length: 100,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
