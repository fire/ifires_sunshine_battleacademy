defmodule SunshinesBattleacademy.Web.LobbyChannel do
  use Phoenix.Channel
  require Logger

  # handles the special `"lobby"` subtopic
  def join("room:lobby", message, socket) do
    # init(%{socket: socket})
    ConCache.put(:game_map, :player_list, Map.new)
    send(self, :after_join)
    {:ok, socket}
  end

  def terminate(reason, socket) do
    ConCache.update(:game_map, :player_list, fn(old_value) ->
      case old_value do
        nil -> {:ok, nil}
        value -> {:ok, Map.delete(old_value, socket.assigns[:user_id])}
      end
    end)
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_info(:after_join, socket) do
    uid = UUID.uuid4
    push socket, "welcome", %{id: uid}
    ConCache.put(:game_map, socket.assigns[:user_id], %{id: uid})
    {:noreply, socket}
  end

  def handle_in("gotit", payload, socket) do
    ConCache.update_existing(:game_map, socket.assigns[:user_id], fn(old) ->
      ConCache.update(:game_map, :player_list, fn(old_value) ->
        case old_value do
          nil -> {:ok, Map.put(Map.new, socket.assigns[:user_id], old[:id])}
          value -> {:ok, Map.put(value, socket.assigns[:user_id], old[:id])}
        end
      end)

      {:ok, %{id: old[:id], nickname: payload["nickname"], hue: payload["hue"], target: %{x: 0,y: 0}, position: %{x: 0,y: 0}}}
    end)
    {:noreply, socket}
  end

  def handle_in("movement", %{"target" => %{"x" => tx, "y" => ty}}, socket) do
    ConCache.update_existing(:game_map, socket.assigns[:user_id], fn(old_value) ->
      {:ok, %{old_value | target: %{x: tx, y: ty}}}
    end)

    players = ConCache.get(:game_map, :player_list)
    #Logger.debug inspect players
    map = for n <- Map.to_list(players) do
      #Logger.debug inspect n
      {user_id, id} = n

      ConCache.update_existing(:game_map, user_id, fn(elem) ->
        #Logger.debug inspect elem
        # normalize the target direction, if necessary, and add to position
        tx = elem.target[:x] / 10
        ty = elem.target[:y] / 10
        length = :math.sqrt((tx*tx) + (ty*ty))
        target = if length > 15 do
          %{x: (tx / length) * 15, y: (ty / length) * 15}
        else
          %{x: tx, y: ty}
        end
        new_position = %{x: elem.position[:x] + target[:x], y: elem.position[:y] + target[:y]}
        {:ok, %{elem | position: new_position}}
      end)

      ConCache.get(:game_map, user_id)[:position]
      # Use target to calculate a new position for this player
    end
    push socket, "state_update", %{map: map}
    {:noreply, socket}
  end

  def init(state) do
    #schedule_work()
    {:ok, state}
  end

  # def handle_info(:work, state) do
  #   schedule_work() # Reschedule once more
  #   {:noreply, state.socket}
  # end

  # defp schedule_work() do
  #   Process.send_after(self(), :work, div(1000, 10))
  # end
end
