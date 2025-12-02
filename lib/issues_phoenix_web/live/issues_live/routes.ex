defmodule IssuesPhoenixWeb.IssuesLive.Routes do
  use IssuesPhoenixWeb, :live_view

  alias IssuesPhoenix.{RouteScanner, TrackedRoutes, Config}

  @impl true
  def mount(_params, _session, socket) do
    router = Config.router()
    scanned_routes = RouteScanner.scan_routes(router)
    tracked_routes = TrackedRoutes.list_tracked_routes()

    # Mark which scanned routes are already tracked
    tracked_paths =
      MapSet.new(tracked_routes, fn tr -> {tr.path, tr.method} end)

    scanned_with_status =
      Enum.map(scanned_routes, fn route ->
        tracked? = MapSet.member?(tracked_paths, {route.path, route.method})
        Map.put(route, :tracked?, tracked?)
      end)

    {:ok,
     socket
     |> assign(:page_title, "Manage Routes")
     |> assign(:scanned_routes, scanned_with_status)
     |> assign(:tracked_routes, tracked_routes)
     |> assign(:router, inspect(router))
     |> assign(:editing_route_id, nil)
     |> assign(:edit_form, nil)}
  end

  @impl true
  def handle_event("scan_routes", _params, socket) do
    router = Config.router()
    scanned_routes = RouteScanner.scan_routes(router)
    tracked_routes = TrackedRoutes.list_tracked_routes()

    tracked_paths =
      MapSet.new(tracked_routes, fn tr -> {tr.path, tr.method} end)

    scanned_with_status =
      Enum.map(scanned_routes, fn route ->
        tracked? = MapSet.member?(tracked_paths, {route.path, route.method})
        Map.put(route, :tracked?, tracked?)
      end)

    {:noreply,
     socket
     |> assign(:scanned_routes, scanned_with_status)
     |> put_flash(:info, "Routes scanned successfully. Found #{length(scanned_routes)} routes.")}
  end

  @impl true
  def handle_event("track_route", %{"path" => path, "method" => method}, socket) do
    # Find the route in scanned routes
    route =
      Enum.find(socket.assigns.scanned_routes, fn r ->
        r.path == path && r.method == method
      end)

    if route do
      # Auto-assign display_order as the next available number
      max_order =
        socket.assigns.tracked_routes
        |> Enum.map(& &1.display_order)
        |> Enum.max(fn -> -1 end)

      attrs = %{
        path: route.path,
        method: route.method,
        controller: route.controller,
        action: to_string(route.action || ""),
        route_type: route.type,
        enabled: true,
        display_order: max_order + 1
      }

      case TrackedRoutes.create_tracked_route(attrs) do
        {:ok, _tracked_route} ->
          # Refresh tracked routes
          tracked_routes = TrackedRoutes.list_tracked_routes()

          tracked_paths =
            MapSet.new(tracked_routes, fn tr -> {tr.path, tr.method} end)

          scanned_with_status =
            Enum.map(socket.assigns.scanned_routes, fn r ->
              tracked? = MapSet.member?(tracked_paths, {r.path, r.method})
              Map.put(r, :tracked?, tracked?)
            end)

          {:noreply,
           socket
           |> assign(:scanned_routes, scanned_with_status)
           |> assign(:tracked_routes, tracked_routes)
           |> put_flash(:info, "Route added to tracking")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to track route")}
      end
    else
      {:noreply, put_flash(socket, :error, "Route not found")}
    end
  end

  @impl true
  def handle_event("untrack_route", %{"id" => id}, socket) do
    tracked_route = TrackedRoutes.get_tracked_route!(id)

    case TrackedRoutes.delete_tracked_route(tracked_route) do
      {:ok, _} ->
        # Refresh tracked routes
        tracked_routes = TrackedRoutes.list_tracked_routes()

        tracked_paths =
          MapSet.new(tracked_routes, fn tr -> {tr.path, tr.method} end)

        scanned_with_status =
          Enum.map(socket.assigns.scanned_routes, fn r ->
            tracked? = MapSet.member?(tracked_paths, {r.path, r.method})
            Map.put(r, :tracked?, tracked?)
          end)

        {:noreply,
         socket
         |> assign(:scanned_routes, scanned_with_status)
         |> assign(:tracked_routes, tracked_routes)
         |> put_flash(:info, "Route removed from tracking")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove route")}
    end
  end

  @impl true
  def handle_event("toggle_enabled", %{"id" => id}, socket) do
    tracked_route = TrackedRoutes.get_tracked_route!(id)

    case TrackedRoutes.update_tracked_route(tracked_route, %{enabled: !tracked_route.enabled}) do
      {:ok, _} ->
        tracked_routes = TrackedRoutes.list_tracked_routes()

        {:noreply,
         socket
         |> assign(:tracked_routes, tracked_routes)
         |> put_flash(:info, "Route tracking toggled")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to toggle route")}
    end
  end

  @impl true
  def handle_event("edit_route", %{"id" => id}, socket) do
    tracked_route = TrackedRoutes.get_tracked_route!(id)
    changeset = TrackedRoutes.change_tracked_route(tracked_route)

    {:noreply,
     socket
     |> assign(:editing_route_id, String.to_integer(id))
     |> assign(:edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_route_id, nil)
     |> assign(:edit_form, nil)}
  end

  @impl true
  def handle_event("validate_route", %{"tracked_route" => route_params}, socket) do
    tracked_route = TrackedRoutes.get_tracked_route!(socket.assigns.editing_route_id)

    changeset =
      tracked_route
      |> TrackedRoutes.change_tracked_route(route_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :edit_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_route", %{"tracked_route" => route_params}, socket) do
    tracked_route = TrackedRoutes.get_tracked_route!(socket.assigns.editing_route_id)

    case TrackedRoutes.update_tracked_route(tracked_route, route_params) do
      {:ok, _} ->
        tracked_routes = TrackedRoutes.list_tracked_routes()

        {:noreply,
         socket
         |> assign(:tracked_routes, tracked_routes)
         |> assign(:editing_route_id, nil)
         |> assign(:edit_form, nil)
         |> put_flash(:info, "Route updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :edit_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("move_up", %{"id" => id}, socket) do
    route = TrackedRoutes.get_tracked_route!(id)

    # Find the route directly above (regardless of category)
    above_route =
      socket.assigns.tracked_routes
      |> Enum.filter(fn r -> r.display_order < route.display_order end)
      |> Enum.max_by(& &1.display_order, fn -> nil end)

    if above_route do
      # Swap display_order values
      TrackedRoutes.update_tracked_route(route, %{display_order: above_route.display_order})
      TrackedRoutes.update_tracked_route(above_route, %{display_order: route.display_order})

      tracked_routes = TrackedRoutes.list_tracked_routes()
      {:noreply, assign(socket, :tracked_routes, tracked_routes)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_down", %{"id" => id}, socket) do
    route = TrackedRoutes.get_tracked_route!(id)

    # Find the route directly below (regardless of category)
    below_route =
      socket.assigns.tracked_routes
      |> Enum.filter(fn r -> r.display_order > route.display_order end)
      |> Enum.min_by(& &1.display_order, fn -> nil end)

    if below_route do
      # Swap display_order values
      TrackedRoutes.update_tracked_route(route, %{display_order: below_route.display_order})
      TrackedRoutes.update_tracked_route(below_route, %{display_order: route.display_order})

      tracked_routes = TrackedRoutes.list_tracked_routes()
      {:noreply, assign(socket, :tracked_routes, tracked_routes)}
    else
      {:noreply, socket}
    end
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
          <h1>Manage Routes</h1>
          <p>Scan your application routes and select which ones to track for issues.</p>
          <div class="actions">
            <button phx-click="scan_routes">Scan Routes</button>
            <.link navigate="/dev/issues" role="button" class="secondary">Back to Issues</.link>
          </div>
        </div>
        
      <!-- Tracked Routes Section -->
        <section>
          <header>
            <h3>Currently Tracked Routes ({length(@tracked_routes)})</h3>
          </header>

          <%= if @tracked_routes == [] do %>
            <article>
              <p>
                No routes are being tracked yet. Click "Scan Routes" and select routes below to start tracking.
              </p>
            </article>
          <% else %>
            <table class="striped" style="font-size: 0.875rem;">
              <thead>
                <tr>
                  <th scope="col">Order</th>
                  <th scope="col">Route</th>
                  <th scope="col">Category</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                <%= for route <- @tracked_routes do %>
                  <tr class={if(@editing_route_id == route.id, do: "editing", else: "")}>
                      <td>
                        <div>
                          <span class="badge">{route.display_order}</span>
                          <div>
                            <button
                              type="button"
                              phx-click="move_up"
                              phx-value-id={route.id}
                              class="icon-btn"
                              title="Move up"
                            >▲</button>
                            <button
                              type="button"
                              phx-click="move_down"
                              phx-value-id={route.id}
                              class="icon-btn"
                              title="Move down"
                            >▼</button>
                          </div>
                        </div>
                      </td>
                    <td>
                      <code style="font-size: 0.75rem;">{route.method}</code> {route.path} <br/>
                      <.route_type_badge type={route.route_type} />
                    </td>
                    <%= if @editing_route_id == route.id do %>
                      <!-- Edit mode with form -->
                      <td colspan="4">
                        <.form
                          for={@edit_form}
                          phx-change="validate_route"
                          phx-submit="save_route"
                        >
                          <div style="display: flex; gap: 0.5rem; align-items: end;">
                            <.input
                              field={@edit_form[:category]}
                              type="text"
                              label="Category"
                              placeholder="e.g., Authentication, Posts"
                            />
                            <button
                              type="submit"
                              style="padding: 0.25rem 0.5rem; font-size: 0.75rem;"
                            >
                              Save
                            </button>
                            <button
                              type="button"
                              phx-click="cancel_edit"
                              class="outline secondary"
                              style="padding: 0.25rem 0.5rem; font-size: 0.75rem;"
                            >
                              Cancel
                            </button>
                          </div>
                        </.form>
                      </td>
                    <% else %>
                      <td>{route.category || "-"}</td>
                      <td>
                        <button
                          phx-click="toggle_enabled"
                          phx-value-id={route.id}
                          class={"badge " <> if(route.enabled, do: "badge-resolved", else: "badge-closed")}
                          style="cursor: pointer; font-size: 0.75rem;"
                        >
                          {if route.enabled, do: "Enabled", else: "Disabled"}
                        </button>
                      </td>
                      <td>
                        <div style="display: flex; gap: 0.25rem;">
                          <button
                            phx-click="edit_route"
                            phx-value-id={route.id}
                            class="outline"
                            style="padding: 0.25rem 0.5rem; font-size: 0.75rem;"
                          >
                            Edit
                          </button>
                          <button
                            phx-click="untrack_route"
                            phx-value-id={route.id}
                            data-confirm="Are you sure? This will not delete associated issues."
                            class="outline secondary"
                            style="padding: 0.25rem 0.5rem; font-size: 0.75rem;"
                          >
                            Untrack
                          </button>
                        </div>
                      </td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </section>
        
      <!-- Available Routes Section -->
        <section>
          <header>
            <h3>Available Routes ({length(@scanned_routes)})</h3>
          </header>

          <table class="striped" style="font-size: 0.875rem;">
            <thead>
              <tr>
                <th scope="col">Route</th>
                <th scope="col">Controller/LiveView</th>
                <th scope="col">Type</th>
                <th scope="col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for route <- @scanned_routes do %>
                <tr class={if route.tracked?, do: "tracked"}>
                  <td>
                    <code style="font-size: 0.75rem;">{route.method}</code> {route.path}
                  </td>
                  <td style="font-size: 0.8rem;"><small>{route.controller}#{route.action}</small></td>
                  <td><.route_type_badge type={route.type} /></td>
                  <td>
                    <%= if route.tracked? do %>
                      <span class="badge badge-resolved">Tracked</span>
                    <% else %>
                      <button
                        phx-click="track_route"
                        phx-value-path={route.path}
                        phx-value-method={route.method}
                        class="outline"
                        style="padding: 0.25rem 0.5rem; font-size: 0.75rem;"
                      >
                        Track
                      </button>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </section>
      </div>
    </div>
    """
  end

  defp route_type_badge(assigns) do
    {class, text} =
      case assigns.type do
        :controller -> {"badge-in-progress", "Controller"}
        :live_view -> {"badge-open", "LiveView"}
      end

    assigns = assign(assigns, :class, class) |> assign(:text, text)

    ~H"""
    <span class={"badge #{@class}"}>
      {@text}
    </span>
    """
  end
end
