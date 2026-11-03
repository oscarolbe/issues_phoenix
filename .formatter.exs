locals_without_parens = [issues_phoenix_routes: 1, issues_phoenix_routes: 2]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,dev,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
