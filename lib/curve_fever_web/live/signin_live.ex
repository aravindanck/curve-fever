defmodule CurveFeverWeb.SigninLive do
  use CurveFeverWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{}, as: :signin)
    {:ok, assign(socket, form: form)}
  end

  @impl true
  def handle_event("enter-lobby", %{"player_name" => player_name} = _params, socket) do
    socket =
      socket
      |> push_navigate(to: ~p"/lobby?player_name=#{player_name}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="container">
      <.header>Curve Fever</.header>
    </section>
    <div id="signin-container" class="container row">
      <div class="column">
        <.simple_form for={@form} id="signin_form" phx-submit="enter-lobby">
          <.input name={:player_name} value="" placeholder="Player Name" />
          <:actions>
            <.button class="bg-beige">Enter</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
