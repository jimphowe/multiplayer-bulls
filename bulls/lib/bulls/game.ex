defmodule Bulls.Game do
  # This module doesn't do stuff,
  # it computes stuff.
  def new do
    %{
      secret: random_secret(),
      observers: MapSet.new(),
      players: MapSet.new(),
      players_ready: %{},
      guesses: %{},
      current_guesses: %{},
      winLoss: %{},
      game_started: false,
      view: "",
    }
  end

  def addUser(st, name) do
    IO.puts "addUser:"
    IO.puts name

    observers = MapSet.put(st.observers, name)

    %{
      secret: st.secret,
      observers: observers,
      players: st.players,
      players_ready: st.players_ready,
      guesses: st.guesses,
      current_guesses: st.current_guesses,
      winLoss: Map.put(st.winLoss, name, %{:win => 0, :loss => 0}),
      game_started: st.game_started,
      view: st.view,
    }
  end

  def addPlayer(st, name) do
    observers = MapSet.delete(st.observers, name)
    players = MapSet.put(st.players, name)
    players_ready = Map.put(st.players_ready, name, false)

    guesses = Map.put(st.guesses, name, [])

    current_guesses = Map.put(st.current_guesses, name, "")

    %{
      secret: st.secret,
      observers: observers,
      players: players,
      players_ready: players_ready,
      guesses: guesses,
      current_guesses: current_guesses,
      winLoss: st.winLoss,
      game_started: st.game_started,
      view: st.view,
    }
  end

  def addObserver(st, name) do
    observers = MapSet.put(st.observers, name)
    players = MapSet.delete(st.players, name)
    players_ready = Map.delete(st.players_ready, name)

    guesses = Map.delete(st.guesses, name)
    current_guesses = Map.delete(st.current_guesses, name)

    %{
      secret: st.secret,
      observers: observers,
      players: players,
      players_ready: players_ready,
      guesses: guesses,
      current_guesses: current_guesses,
      winLoss: st.winLoss,
      game_started: st.game_started,
      view: st.view,

    }
  end

  def ready(st, name) do

    players_ready = Map.put(st.players_ready, name, true)
    game_started = Enum.all?(Map.values(players_ready))



    %{
      secret: st.secret,
      observers: st.observers,
      players: st.players,
      players_ready: players_ready,
      guesses: st.guesses,
      current_guesses: st.current_guesses,
      winLoss: st.winLoss,
      game_started: game_started,
      view: st.view,

    }
  end

  def notReady(st, name) do

    players_ready = Map.put(st.players_ready, name, false)

    %{
      secret: st.secret,
      observers: st.observers,
      players: st.players,
      players_ready: players_ready,
      guesses: st.guesses,
      current_guesses: st.current_guesses,
      winLoss: st.winLoss,
      game_started: st.game_started,
      view: st.view,

    }
  end



  defp updateArr(guess, secret, arr, idx) do
    if Enum.member?(guess, Enum.at(secret, idx)) do
      if Enum.at(guess, idx) == Enum.at(secret, idx) do
        [Enum.at(arr, 0) + 1, Enum.at(arr, 1)]
      else
        [Enum.at(arr, 0), Enum.at(arr, 1) + 1]
      end
    else
      arr
    end
  end

  defp numberOfBullsAndCows(guess, secret, arr, idx) do

    cond do
      idx == Enum.count(secret) -> [Integer.to_string(Enum.at(arr, 0)), Integer.to_string(Enum.at(arr, 1))]
      true -> numberOfBullsAndCows(guess,
                secret,
                updateArr(guess, secret, arr, idx),
                idx + 1)
    end
  end

  defp renderView(st, guesses, acc) do

    if Enum.count(guesses) == 0 do
      acc
    else

      numBC = numberOfBullsAndCows(String.graphemes(Enum.at(guesses, 0)), String.graphemes(st.secret), [0, 0], 0)
      renderView(st,
        Enum.slice(guesses, 1, Enum.count(guesses) - 1),
        acc
        <> " "
        <> Enum.at(guesses,0)
           <> " "
           <> Enum.at(numBC,0)
              <> "B "
              <> Enum.at(numBC,1)
                 <> "C"
                 <> "\n")
    end
  end

  defp notEmptyString(value) do

    result = false
    result = if value != "" do
      true
    end
    result
  end

  defp updateWins(key, value, current_guesses, secret) do
    if Map.has_key?(current_guesses, key) do
      if (Map.get(current_guesses, key) == secret) do
        %{:win => Map.get(value, :win) + 1, :loss => Map.get(value, :loss)}
      else
        %{:win => Map.get(value, :win), :loss => Map.get(value, :loss) + 1}
      end
    else
      value
    end
  end


  def guess(st, codeGuess, name) do

    guesses = st.guesses
    current_guesses = Map.put(st.current_guesses, name, codeGuess)

    has_guess_list = Enum.map(current_guesses, fn({k, v}) -> notEmptyString(v) end)

    flag = Enum.all?(has_guess_list)

    length_of_guesses = Enum.count(Map.get(guesses, name))

    guesses =
      if flag do

        Map.new(current_guesses, fn {k, v} -> {k, (Map.get(st.guesses, k) ++ [v])} end)
      else
        guesses
      end

    guesses_Processed =
      if (Enum.count(Map.get(guesses, name)) == (length_of_guesses + 1)) do
        true
      else
        false
      end

    secret_Found =
      if (guesses_Processed) do
        Enum.any?(Map.values(current_guesses), fn(s) -> s == st.secret end)
      else
        false
      end

    secret =
      if (secret_Found) do
        random_secret()
      else
        st.secret
      end

    players_ready =
      if (secret_Found) do
        Map.new(st.players_ready, fn {k, v} -> {k, false} end)
      else
        st.players_ready
      end

    game_started =
      if (secret_Found) do
        false
      else
        true
      end
    guesses =
      if (secret_Found) do
        Map.new(guesses, fn {k, v} -> {k, []} end)
      else
        guesses
      end

    winLoss =
      if (secret_Found) do
        Map.new(st.winLoss, fn {k, v} -> {k, updateWins(k, v, current_guesses, st.secret)} end)
      else
        st.winLoss
      end

    current_guesses =
      if flag do
        Map.new(current_guesses, fn {k, v} -> {k, ""} end)
      else
        current_guesses
      end

    %{
      secret: secret,
      observers: st.observers,
      players: st.players,
      players_ready: players_ready,
      guesses: guesses,
      current_guesses: current_guesses,
      winLoss: winLoss,
      game_started: game_started,
      view: st.view,

    }
  end


  def reset(st) do

    %{
      secret: random_secret(),
      observers: MapSet.union(st.observers,st.players),
      players: MapSet.new(),
      players_ready: %{},
      guesses: %{},
      current_guesses: %{},
      winLoss: %{},
      game_started: false,
      view: "",

    }

  end

  def view(st, name) do

    winLoss = Enum.map(st.winLoss, fn({k, v}) -> (k <> ": " <> Integer.to_string(Map.get(v, :win)) <> "W " <> Integer.to_string(Map.get(v, :loss)) <> "L") end)

    values = Map.values(st.guesses)


    view = Enum.map(st.guesses, fn({k, v}) -> (k <> "\n" <> renderView(st, v, "")) end)

    %{

      observers: MapSet.to_list(st.observers),
      players: MapSet.to_list(st.players),
      players_ready: st.players_ready,
      guesses: st.guesses,
      current_guesses: st.current_guesses,
      winLoss: winLoss,
      game_started: st.game_started,
      view: view,
      name: name,

    }
  end

  def build_secret(secret) do
    if String.length(secret) == 4 do
      secret
    else
      new_val = Integer.to_string(Enum.random(0..9))
      if secret =~ new_val do
        build_secret(secret)
      else
        build_secret(secret <> new_val)
      end
    end
  end

  def random_secret() do
    build_secret("")
  end
end