defmodule Bulls.GameServer do
  use GenServer

  alias Bulls.BackupAgent
  alias Bulls.Game

  # public interface

  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new
    GenServer.start_link(
      __MODULE__,
      game,
      name: reg(name)
    )
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def addUser(name, person) do
    GenServer.call(reg(name), {:addUser, name, person})
  end

  def switchToObserver(name, person) do
    GenServer.call(reg(name), {:observer, name, person})
  end

  def switchToPlayer(name, person) do
    GenServer.call(reg(name), {:player, name, person})
  end

  def ready(name, person) do
    GenServer.call(reg(name), {:ready, name, person})
  end

  def notReady(name, person) do
    GenServer.call(reg(name), {:notReady, name, person})
  end

  def guess(name, letter, nn) do
    GenServer.call(reg(name), {:guess, name, letter, nn})
  end

  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end


  # implementation
  def init(game) do
    {:ok, game}
  end

  def handle_call({:reset, name}, _from, game) do
    game = Game.reset(game)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:addUser, name, person}, _from, game) do
    game = Game.addUser(game, person)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:observer, name, person}, _from, game) do
    game = Game.addObserver(game, person)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:player, name, person}, _from, game) do
    game = Game.addPlayer(game, person)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:ready, name, person}, _from, game) do
    game = Game.ready(game, person)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:notReady, name, person}, _from, game) do
    game = Game.notReady(game, person)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end


  def handle_call({:guess, name, letter, nn}, _from, game) do
    game = Game.guess(game, letter, nn)
    BackupAgent.put(name, game)
    {:reply, game, game}
  end

  def handle_call({:peek, _name}, _from, game) do
    {:reply, game, game}
  end

end
