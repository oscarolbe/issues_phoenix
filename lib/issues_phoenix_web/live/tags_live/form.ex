defmodule IssuesPhoenixWeb.TagsLive.Form do
  use IssuesPhoenixWeb, :live_view

  alias IssuesPhoenix.Config
  alias IssuesPhoenix.Schemas.Tag

  @impl true
  def mount(_params, _session, socket) do
    changeset = change_tag()

    {:ok,
     socket
     |> assign(:page_title, "Create New Tag")
     |> assign(:form, to_form(changeset, as: "tag"))
     |> assign(:issues_phoenix_class, "issues-phoenix")
     |> assign(:assets_path, Config.assets_path())}
  end

  defp change_tag(params \\ %{}) do
    types = %{name: :string}
    {%{}, types}
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_length(:name, min: 1, max: 100)
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "tag"))}
  end

  @impl true
  def handle_event("save", %{"tag" => tag_params}, socket) do
    changeset = change_tag(tag_params)

    if changeset.valid? do
      tag_name = Ecto.Changeset.get_field(changeset, :name) |> String.trim()

      # Create the tag or get existing one
      tag =
        case Config.repo().get_by(Tag, name: tag_name) do
          nil -> Config.repo().insert!(%Tag{name: tag_name})
          existing -> existing
        end

      {:noreply,
       socket
       |> put_flash(:info, "Tag '#{tag.name}' created successfully")
       |> push_navigate(to: get_return_path(socket))}
    else
      {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "tag"))}
    end
  end

  defp get_return_path(socket) do
    # Check if there's a return_to in the params, otherwise default to issues index
    case socket.assigns[:live_action] do
      _ -> "/dev/issues/new"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@issues_phoenix_class}>
      <div class="container">
        <div class="headings">
          <h1>{@page_title}</h1>
          <p>Create a new tag to categorize issues.</p>
          <div class="actions">
            <.link navigate="/dev/issues/new" class="secondary">Cancel</.link>
          </div>
        </div>

        <.form
          for={@form}
          phx-change="validate"
          phx-submit="save"
          class="mt-8"
        >
          <fieldset>
            <label>
              Tag Name *
              <.input
                field={@form[:name]}
                type="text"
                placeholder="Enter tag name..."
                phx-debounce="300"
              />
              <small>Tags help you organize and filter issues by topic or category.</small>
            </label>
          </fieldset>

          <div class="grid">
            <.button type="submit" disabled={!@form.source.valid?}>
              Create Tag
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
