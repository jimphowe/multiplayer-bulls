defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.Game
  alias Bulls.GameServer

  @impl true
  def join("game:" <> name, payload, socket) do
    if authorized?(payload) do
      GameServer.start(name)
      socket = socket
               |> assign(:name, name)
               |> assign(:user, "")
      game = GameServer.peek(name)
      view = Game.view(game, "")
      {:ok, view, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("login", %{"name" => user}, socket) do
    socket = assign(socket, :user, user)
    view = socket.assigns[:name]
           |> GameServer.peek()
           |> Game.view(user)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("addUser", %{"name" => person}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
           |> GameServer.addUser(person)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("observer", %{"user" => person}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
           |> GameServer.switchToObserver(person)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("player", %{"user" => person}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
           |> GameServer.switchToPlayer(person)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("ready", %{"user" => person}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
           |> GameServer.ready(person)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("notReady", %{"user" => person}, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name]
           |> GameServer.notReady(person)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("guess", %{"letter" => ll, "username" => nn }, socket) do
    user = socket.assigns[:user]
    IO.puts user
    view = socket.assigns[:name]
           |> GameServer.guess(ll, nn)
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  @impl true
  def handle_in("reset", _, socket) do
    user = socket.assigns[:user]
    view = socket.assigns[:name] # game name
           |> GameServer.reset()
           |> Game.view(user)
    broadcast(socket, "view", view)
    {:reply, {:ok, view}, socket}
  end

  intercept ["view"]

  @impl true
  def handle_out("view", msg, socket) do
    user = socket.assigns[:user]
    msg = %{msg | name: user}
    push(socket, "view", msg)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
