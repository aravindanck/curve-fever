defmodule CurveFeverWeb.SigninLive do
  use CurveFeverWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, player_name: "")}
  end

  @impl true
  def handle_event("enter-lobby", %{"signin_form" => fields}, socket) do
    %{"player_name" => player_name} = fields

    Logger.info("Entering the lobby")
    Logger.info(player_name: player_name)

    payload = %{
      player_name: player_name
    }

    send(self(), {:enter_lobby, payload})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:enter_lobby, attrs}, socket) do

    %{player_name: player_name} = attrs

    Logger.info(player_name: player_name)

    url = Routes.lobby_path(
        socket,
        :join,
        player_name: player_name)

    Logger.info(url: url)

    socket = socket
    |> put_temporary_flash(:info, "Entered the lobby")
    |> push_redirect(to: url)

    {:noreply, socket}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
