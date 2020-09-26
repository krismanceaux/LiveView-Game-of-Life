defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias Components.CellComponent

  # TODO: Scrub the cells that don't fit on the grid to prevent memory issues
  # TODO: Hitting the start button more than once will essentially sart another game on top of the current game, looks like it doubles and triples in speed
  # TODO: Look into what refreshing the page does to the socket -> does another Life supervisory tree start up in mount/3? I am a little ignorant here...
  def mount(_params, _session, socket) do
    Life.Supervisor.start_link()
    socket = assign(socket, color: "cyan", live_cells: [])
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <%= for i <- 0..50 do %>
    <div class="row">

      <%= for j <- 0..50 do %>
      <%= live_component @socket, CellComponent, id: "#{i},#{j}", color: @color %>
      <% end %>

    </div>
    <% end %>

    <button phx-click="start_game">Start</button>


    <style>
      .row{
        margin: 1px;
      }
      .coral{
        background-color: coral;
      }
      .cyan{
        background-color: cyan;
      }
      .cell{
        height: 10px;
        width: 10px;
        padding: 10px;
        margin: 0px 1px;
      }
    </style>
    """
  end

  def handle_info({:toggle, cell}, socket) do
    send_update(CellComponent, id: cell.id, color: cell.color)

    live_cells =
      case cell.color do
        "coral" ->
          [cell.id | socket.assigns.live_cells]

        "cyan" ->
          socket.assigns.live_cells
          |> Enum.filter(&(&1 != cell.id))
      end

    updated_socket = assign(socket, live_cells: live_cells)

    {:noreply, updated_socket}
  end

  def handle_info(:tick, socket) do
    live_cells =
      socket.assigns.live_cells
      |> Enum.map(&convert_id_to_tuple/1)

    next_gen_tuple = Life.GameServer.run_game(live_cells, 10)

    cells_to_die =
      live_cells
      |> Enum.flat_map(&if(&1 not in next_gen_tuple, do: [&1], else: []))
      |> Enum.map(&convert_tuple_to_id(&1))

    next_gen = Enum.map(next_gen_tuple, &convert_tuple_to_id/1)

    for id <- cells_to_die, do: send_update(CellComponent, id: id, color: "cyan")
    for id <- next_gen, do: send_update(CellComponent, id: id, color: "coral")

    socket = assign(socket, live_cells: next_gen)
    {:noreply, socket}
  end

  def handle_event("start_game", _, socket) do
    if connected?(socket) do
      :timer.send_interval(100, self(), :tick)
    end

    {:noreply, socket}
  end

  defp convert_id_to_tuple(id) do
    [x, y] = String.split(id, ",")
    {x, _} = Integer.parse(x)
    {y, _} = Integer.parse(y)
    {x, y}
  end

  defp convert_tuple_to_id(tuple) do
    "#{elem(tuple, 0)},#{elem(tuple, 1)}"
  end
end
