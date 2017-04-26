defmodule SunshinesBattleacademy.Web.LobbyChannel do
  use Phoenix.Channel
  require Logger

  # handles the special `"lobby"` subtopic
  def join("room:lobby", _message, socket) do
    :timer.send_interval(50, :work)
    send(self(), :after_join)
    {:ok, socket}
  end

  def terminate(reason, socket) do
    #ConCache.update_existing(:game_map, :player_list, fn(old_value) ->
    #  {:ok, Map.delete(old_value, socket.assigns[:user_id])}
    #end)
    # Fetch entire player
    player = SunshinesBattleacademy.Repo.get(SunshinesBattleacademy.GameItem, UUID.string_to_binary!(socket.assigns[:user_id]))  
      |> SunshinesBattleacademy.Repo.preload(:position)
      |> SunshinesBattleacademy.Repo.preload(:target)
    # Delete entire player
    #SunshinesBattleacademy.Repo.delete(player)

    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_info(:work, socket) do
    players = SunshinesBattleacademy.Repo.all(SunshinesBattleacademy.GameItem)

    target = SunshinesBattleacademy.Repo.get(SunshinesBattleacademy.GameItem, "")  
      |> SunshinesBattleacademy.Repo.preload(:position)
    
    # TODO
    # if target == nil do
    # else
    #   target = normalize_target(elem.target)
    #   new_position = %{x: elem.position[:x] + target[:x], y: elem.position[:y] + target[:y]}
    #   {:ok, %{elem | position: new_position}}
    # end

    # map = for {user_id, _id} <- players do
    #   ConCache.get(:game_map, user_id)
    #   # Use target to calculate a new position for this player
    # end
    # push socket, "state_update", %{map: map}
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    push socket, "welcome", %{id: socket.assigns[:user_id]}
    # ConCache.put(:game_map, socket.assigns[:user_id], %{id: uid})

    # ConCache.update(:game_map, :player_list, fn(old_value) ->
    #   if old_value == nil do
    #     {:ok, Map.put(Map.new, socket.assigns[:user_id], uid)}
    #   else
    #     {:ok, Map.put(old_value, socket.assigns[:user_id], uid)}
    #   end
    # end)

    {:noreply, socket}
  end
  def handle_in("gotit", %{"nickname" => nickname, "hue" => hue}, socket) do
    {hue, _} = Integer.parse(hue)

    SunshinesBattleacademy.Repo.insert(%SunshinesBattleacademy.GameItem{nickname: nickname, hue: hue, target: %SunshinesBattleacademy.Target{x: 0,y: 0}, position: %SunshinesBattleacademy.Position{x: 0,y: 0}})
    # ConCache.update_existing(:game_map, socket.assigns[:user_id], fn(old_player) ->
    #   {:ok, }
    # end)
    {:noreply, socket}
  end

  def handle_in("movement", payload, socket) do


   # ConCache.update_existing(:game_map, socket.assigns[:user_id], fn(old_value) ->
   #   if old_value[:target] == nil do
   #    {:noreply, socket}
   #   else
   #     {:ok, %{old_value | target: %{x: payload["target"]["x"], y: payload["target"]["y"]}}}
   #   end
   # end)

    player = SunshinesBattleacademy.Repo.get(SunshinesBattleacademy.GameItem, UUID.string_to_binary!(socket.assigns[:user_id]))  
      |> SunshinesBattleacademy.Repo.preload(:position)
      |> SunshinesBattleacademy.Repo.preload(:target)

    {:noreply, socket}
  end

  def normalize_target(target) do
    tx = target[:x] / 10
    ty = target[:y] / 10
    length = :math.sqrt((tx*tx) + (ty*ty))
    if length > 15 do
      %{x: (tx / length) * 15, y: (ty / length) * 15}
    else
      %{x: tx, y: ty}
    end
  end
end
