defmodule IssuesPhoenixWeb.CoreComponents do
  @moduledoc """
  Provides core UI components styled with Pico CSS (semantic HTML).

  Pico CSS automatically styles semantic HTML elements, so most components
  don't need classes. Components are minimal and leverage HTML5 semantics.
  """
  use Phoenix.Component
  use Gettext, backend: IssuesPhoenixWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button.

  Pico CSS automatically styles `<button>` and `<a role="button">` elements.

  ## Examples

      <.button>Send!</.button>
      <.button navigate="/">Home</.button>
      <.button variant="primary">Save</.button>
  """
  attr :type, :string, default: nil
  attr :variant, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value href navigate patch method download)
  slot :inner_block, required: true

  def button(%{navigate: _} = assigns) do
    ~H"""
    <a role="button" href={@rest[:navigate]} data-phx-link="redirect" data-phx-link-state="push">
      {render_slot(@inner_block)}
    </a>
    """
  end

  def button(%{patch: _} = assigns) do
    ~H"""
    <a role="button" href={@rest[:patch]} data-phx-link="patch" data-phx-link-state="push">
      {render_slot(@inner_block)}
    </a>
    """
  end

  def button(%{href: _} = assigns) do
    ~H"""
    <a role="button" href={@rest[:href]}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  def button(assigns) do
    ~H"""
    <button type={@type} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  Pico CSS automatically styles `<input>`, `<select>`, and `<textarea>` elements.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkboxes"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset">
      <label>
        <span :if={@label}>{@label}</span>
        <select id={@id} name={@name} multiple={@multiple} {@rest}>
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset">
      <label>
        <span :if={@label}>{@label}</span>
        <textarea id={@id} name={@name} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div class="fieldset">
      <label>
        <input type="checkbox" id={@id} name={@name} value="true" checked={@checked} {@rest} />
        <span :if={@label}>{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="fieldset">
      <label>
        <span :if={@label}>{@label}</span>
        <input type={@type} name={@name} id={@id} value={Phoenix.HTML.Form.normalize_value(@type, @value)} {@rest} />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <small style="color: var(--pico-color-red-600);">
      {render_slot(@inner_block)}
    </small>
    """
  end

  @doc """
  Renders flash notices using Pico CSS.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "arbitrary HTML attributes"
  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <article
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      style="position: fixed; top: 1rem; right: 1rem; max-width: 400px; z-index: 1000; cursor: pointer;"
      {@rest}
    >
      <strong :if={@title}>{@title}</strong>
      <p>{msg}</p>
    </article>
    """
  end

  @doc """
  Renders a [Hero Icon](https://heroicons.com).

  Hero icons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="size-4" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector, time: 300)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 200)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(IssuesPhoenixWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(IssuesPhoenixWeb.Gettext, "errors", msg, opts)
    end
  end

  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
