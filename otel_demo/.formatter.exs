locals_without_parens = [
  # OtelDemo.OTel
  with_span: 1,
  with_span: 2,
  with_span: 3,
  with_span: 4,
  return_span_attrs: 2,

  # Decorators
  return_with_span_attrs: 2
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
