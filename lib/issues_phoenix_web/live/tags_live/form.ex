defmodule IssuesPhoenixWeb.TagsLive.Form do
  use IssuesPhoenixWeb, :live_view

  alias IssuesPhoenix.Issues

  @impl true
  def mount(_params, _session, socket) do
    changeset = change_tag()

    {:ok,
     socket
     |> assign(:page_title, "Create New Tag")
     |> assign(:form, to_form(changeset, as: "tag"))}
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

      case Issues.find_or_create_tag(tag_name) do
        {:ok, tag} ->
          {:noreply,
           socket
           |> put_flash(:info, "Tag '#{tag.name}' created successfully")
           |> push_navigate(to: "#{socket.assigns.base_path}/new")}

        {:error, tag_changeset} ->
          {:noreply,
           assign(socket,
             form:
               to_form(%{changeset | errors: tag_changeset.errors, action: :insert}, as: "tag")
           )}
      end
    else
      {:noreply, assign(socket, form: to_form(Map.put(changeset, :action, :validate), as: "tag"))}
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
            <.link navigate={"#{@base_path}/new"} class="secondary">Cancel</.link>
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
