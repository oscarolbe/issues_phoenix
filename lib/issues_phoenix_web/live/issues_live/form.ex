defmodule IssuesPhoenixWeb.IssuesLive.Form do
  use IssuesPhoenixWeb, :live_view
  import Ecto.Query

  alias IssuesPhoenix.{Issues, TrackedRoutes, Config}
  alias IssuesPhoenix.Schemas.{Issue, Tag}

  @impl true
  def mount(params, _session, socket) do
    issue_id = Map.get(params, "id")

    {issue, page_title} =
      if issue_id do
        issue = Issues.get_issue!(issue_id) |> Config.repo().preload([:tracked_route, :tags])
        {issue, "Edit Issue"}
      else
        {%Issue{}, "New Issue"}
      end

    tracked_routes = TrackedRoutes.list_tracked_routes(enabled: true)

    # Group routes by category for better organization
    grouped_routes = Enum.group_by(tracked_routes, & &1.category)

    # Build route options for select input with optgroups
    route_options = build_route_options(grouped_routes)

    # Get all existing tags
    all_tags = Config.repo().all(Tag)

    # Get existing tags, or empty list for new issues
    existing_tags = if is_list(issue.tags), do: issue.tags, else: []

    existing_route =
      if Ecto.assoc_loaded?(issue.tracked_route), do: issue.tracked_route, else: nil

    form = issue |> Issues.change_issue() |> to_form()

    {:ok,
     socket
     |> assign(:page_title, page_title)
     |> assign(:issue, issue)
     |> assign(:form, form)
     |> assign(:tracked_routes, tracked_routes)
     |> assign(:route_options, route_options)
     |> assign(:all_tags, all_tags)
     |> assign(:selected_tag_ids, Enum.map(existing_tags, & &1.id))
     |> assign(:selected_route, existing_route)
     |> assign(:issues_phoenix_class, "issues-phoenix")
     |> assign(:assets_path, Config.assets_path())}
  end

  @impl true
  def handle_event("validate", %{"issue" => issue_params}, socket) do
    form =
      socket.assigns.issue
      |> Issues.change_issue(issue_params)
      |> Map.put(:action, :validate)
      |> to_form()

    # Update selected route for preview
    selected_route =
      case Map.get(issue_params, "tracked_route_id") do
        "" -> nil
        nil -> nil
        id -> Enum.find(socket.assigns.tracked_routes, &(&1.id == String.to_integer(id)))
      end

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:selected_route, selected_route)}
  end

  @impl true
  def handle_event("save", %{"issue" => issue_params}, socket) do
    save_issue(socket, socket.assigns.issue.id, issue_params)
  end

  @impl true
  def handle_event("update_selected_tags", %{"tags" => tag_ids}, socket) when is_list(tag_ids) do
    selected = Enum.map(tag_ids, &String.to_integer/1)
    {:noreply, assign(socket, selected_tag_ids: selected)}
  end

  @impl true
  def handle_event("update_selected_tags", _params, socket) do
    # No tags selected
    {:noreply, assign(socket, selected_tag_ids: [])}
  end


  defp save_issue(socket, nil, issue_params) do
    # New issue
    case Issues.create_issue(issue_params) do
      {:ok, issue} ->
        # Associate categories and tags
        _issue = associate_relationships(socket, issue)

        {:noreply,
         socket
         |> put_flash(:info, "Issue created successfully")
         |> push_navigate(to: "/dev/issues")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_issue(socket, _id, issue_params) do
    # Update existing issue
    case Issues.update_issue(socket.assigns.issue, issue_params) do
      {:ok, issue} ->
        # Associate categories and tags
        _issue = associate_relationships(socket, issue)

        {:noreply,
         socket
         |> put_flash(:info, "Issue updated successfully")
         |> push_navigate(to: "/dev/issues")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp associate_relationships(socket, issue) do
    repo = Config.repo()

    # Get selected tags
    tags =
      if socket.assigns.selected_tag_ids != [] do
        repo.all(from t in Tag, where: t.id in ^socket.assigns.selected_tag_ids)
      else
        []
      end

    # Associate them
    issue
    |> repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> repo.update!()
  end

  # Build route options for select input with optgroups
  defp build_route_options(grouped_routes) do
    grouped_routes
    |> Enum.sort_by(fn {category, _routes} -> category || "" end)
    |> Enum.map(fn {category, routes} ->
      category_label = if category, do: category, else: "Uncategorized"

      route_options =
        routes
        |> Enum.sort_by(& &1.display_order)
        |> Enum.map(fn route ->
          label = "#{route.method} #{route.path} → #{route.controller}"
          {label, route.id}
        end)

      {category_label, route_options}
    end)
  end
end
