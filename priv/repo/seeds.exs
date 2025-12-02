# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     IssuesPhoenix.Repo.insert!(%IssuesPhoenix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias IssuesPhoenix.{Repo, Category}

# Seed default categories for IssuesPhoenix
IO.puts("Seeding default categories...")

Category.default_categories()
|> Enum.each(fn category_attrs ->
  case Repo.get_by(Category, name: category_attrs.name) do
    nil ->
      %Category{}
      |> Category.changeset(category_attrs)
      |> Repo.insert!()
      IO.puts("  ✓ Created category: #{category_attrs.name}")

    _existing ->
      IO.puts("  - Category already exists: #{category_attrs.name}")
  end
end)

IO.puts("\nSeeding completed!")
