defmodule Components.CellComponent do
  use GameOfLifeWeb, :live_component

  def render(assigns) do
    ~L"""
    <span id="<%= @id %>" class="cell <%= @color %>" phx-click="toggle" phx-target="<%= @myself %>"></span>
    """
  end

  # 1-way data flow: send message to this process (will be handled in game_live.ex) letting it know it wants to toggle the color of the cell
  def handle_event("toggle", _, socket) do
    case socket.assigns.color do
      "cyan" -> send(self(), {:toggle, %{socket.assigns | color: "coral"}})
      "coral" -> send(self(), {:toggle, %{socket.assigns | color: "cyan"}})
    end

    {:noreply, socket}
  end
end
