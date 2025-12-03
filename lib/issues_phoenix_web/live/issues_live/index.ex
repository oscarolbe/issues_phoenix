defmodule IssuesPhoenixWeb.IssuesLive.Index do
  use IssuesPhoenixWeb, :live_view

  alias IssuesPhoenix.{Issues, TrackedRoutes, Config}
  alias IssuesPhoenix.Schemas.Tag

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Issues Tracker")
     |> assign(:filter_status, :open)
     |> assign(:filter_priority, nil)
     |> assign(:filter_tag_id, nil)
     |> reload_data()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  @impl true
  def handle_event("delete_issue", %{"id" => id}, socket) do
    issue = Issues.get_issue!(id)
    {:ok, _} = Issues.delete_issue(issue)

    {:noreply,
     socket
     |> reload_data()
     |> put_flash(:info, "Issue deleted successfully")}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filter_status = if params["status"] == "", do: nil, else: String.to_atom(params["status"] || "")
    filter_tag_id = if params["tag_id"] in [nil, ""], do: nil, else: String.to_integer(params["tag_id"])

    {:noreply,
     socket
     |> assign(:filter_status, filter_status)
     |> assign(:filter_tag_id, filter_tag_id)
     |> reload_data()}
  end

  @impl true
  def handle_event("update_status", %{"issue_id" => id, "status" => status}, socket) do
    issue = Issues.get_issue!(id)

    case Issues.update_issue(issue, %{status: status}) do
      {:ok, _issue} ->
        {:noreply, reload_data(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update status")}
    end
  end

  # Private helpers

  defp reload_data(socket) do
    # Load all base data
    tracked_routes = TrackedRoutes.list_tracked_routes()
    all_tags = Config.repo().all(Tag) |> Enum.sort_by(& &1.name)
    stats = Issues.stats()

    # Load issues with current filters applied
    issues =
      filter_issues_by_tag(
        Issues.list_issues(status: socket.assigns.filter_status)
        |> Config.repo().preload([:tracked_route, :tags]),
        socket.assigns.filter_tag_id
      )

    socket
    |> assign(:issues, issues)
    |> assign(:tracked_routes, tracked_routes)
    |> assign(:all_tags, all_tags)
    |> assign(:stats, stats)
  end

  defp filter_issues_by_tag(issues, nil), do: issues
  defp filter_issues_by_tag(issues, tag_id) do
    Enum.filter(issues, fn issue ->
      Enum.any?(issue.tags, &(&1.id == tag_id))
    end)
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> Map.put_new(:issues_phoenix_class, "issues-phoenix")
      |> Map.put_new(:assets_path, Config.assets_path())

    ~H"""
    <div class={@issues_phoenix_class}>
      <div class="container">
        <div class="headings">
          <h1>Issues Tracker</h1>
          <p>Track and manage issues for your Phoenix application routes.</p>
          <div class="actions">
            <.link navigate="/dev/issues/routes" role="button">
              Manage Routes
            </.link>
            <.link navigate="/dev/issues/new" role="button">
              New Issue
            </.link>
          </div>
        </div>
        
    <!-- Stats Cards -->
        <section class="grid">
          <article>
            <header>Total Issues</header>
            <h2>{@stats.total}</h2>
          </article>
          <article>
            <header>Open</header>
            <h2 style="color: var(--pico-color-amber-550);">{@stats.open}</h2>
          </article>
          <article>
            <header>In Progress</header>
            <h2 style="color: var(--pico-color-blue-550);">{@stats.in_progress}</h2>
          </article>
          <article>
            <header>Resolved</header>
            <h2 style="color: var(--pico-color-green-550);">{@stats.resolved}</h2>
          </article>
        </section>
        
    <!-- Filters -->
        <section>
          <form phx-change="filter">
            <div class="grid">
              <label>
                Status
                <select name="status">
                  <option value="">All</option>
                  <option value="open" selected={@filter_status == :open}>Open</option>
                  <option value="in_progress" selected={@filter_status == :in_progress}>
                    In Progress
                  </option>
                  <option value="resolved" selected={@filter_status == :resolved}>Resolved</option>
                  <option value="closed" selected={@filter_status == :closed}>Closed</option>
                </select>
              </label>
              
              <label>
                Tag
                <select name="tag_id">
                  <option value="">All Tags</option>
                  <%= for tag <- @all_tags do %>
                    <option value={tag.id} selected={@filter_tag_id == tag.id}>{tag.name}</option>
                  <% end %>
                </select>
              </label>
            </div>
          </form>
        </section>
        
    <!-- Issues Table -->
        <section>
          <table class="striped">
            <thead>
              <tr>
                <th scope="col">Title</th>
                <th scope="col">Route</th>
                <th scope="col">Status</th>
                <th scope="col">Priority</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for issue <- @issues do %>
                <tr>
                  <td>{issue.title}</td>
                  <td>
                    <%= if issue.tracked_route do %>
                      <small>
                        <code>{issue.tracked_route.method}</code> {issue.tracked_route.path}
                        <%= if issue.tracked_route.category do %>
                          <br />
                          <span class="muted">{issue.tracked_route.category}</span>
                        <% end %>
                      </small>
                    <% else %>
                      <span class="muted">No route</span>
                    <% end %>
                  </td>
                  <td>
                    <form phx-change="update_status" style="margin-bottom: 0;">
                      <input type="hidden" name="issue_id" value={issue.id} />
                      <select
                        name="status"
                        class={"status-select " <> 
                          case issue.status do
                            :open -> "badge-open"
                            :in_progress -> "badge-in-progress"
                            :resolved -> "badge-resolved"
                            :closed -> "badge-closed"
                          end
                        }
                      >
                        <option value="open" selected={issue.status == :open} style="color: black;">
                          Open
                        </option>
                        <option
                          value="in_progress"
                          selected={issue.status == :in_progress}
                          style="color: black;"
                        >
                          In Progress
                        </option>
                        <option
                          value="resolved"
                          selected={issue.status == :resolved}
                          style="color: black;"
                        >
                          Resolved
                        </option>
                        <option
                          value="closed"
                          selected={issue.status == :closed}
                          style="color: black;"
                        >
                          Closed
                        </option>
                      </select>
                    </form>
                  </td>
                  <td><.priority_badge priority={issue.priority} /></td>
                  <td>
                    <div class="grid">
                      <.link navigate={"/dev/issues/#{issue.id}/edit"}>Edit</.link>
                      <a
                        href="#"
                        phx-click="delete_issue"
                        phx-value-id={issue.id}
                        data-confirm="Are you sure?"
                        class="secondary"
                      >
                        Delete
                      </a>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>

          <%= if @issues == [] do %>
            <article>
              <p>No issues found.</p>
              <.link navigate="/dev/issues/routes">Start by selecting routes to track</.link>
            </article>
          <% end %>
        </section>
      </div>
    </div>
    """
  end

  defp priority_badge(assigns) do
    {class, text} =
      case assigns.priority do
        :low -> {"badge-low", "Low"}
        :medium -> {"badge-medium", "Medium"}
        :high -> {"badge-high", "High"}
        :critical -> {"badge-critical", "Critical"}
      end

    assigns = assign(assigns, :class, class) |> assign(:text, text)

    ~H"""
    <span class={"badge #{@class}"}>
      {@text}
    </span>
    """
  end

  defp apply_filters(socket, _params) do
    # Can add more filter logic here based on params
    socket
  end
end
