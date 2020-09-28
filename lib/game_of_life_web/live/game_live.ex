defmodule GameOfLifeWeb.GameLive do
  use GameOfLifeWeb, :live_view

  alias Components.CellComponent

  @refresh_rate 250

  # MAYBE: Scrub the cells that don't fit on the grid to prevent memory issues
  # TODO: consider removing the refresh rate off of the Life.GameServer.run_game/3 or give it a default value to 0.
  # I think there are issues with synchronizing this with the send_interval function. Lines 76 and 93

  def mount(_params, _session, socket) do
    Life.Supervisor.start_link()
    socket = assign(socket, color: "cyan", live_cells: [], disabled: "", tref: nil)
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
    <span>
      <button phx-click="start_game" <%= @disabled %> >Start</button>
      <button phx-click="stop_game"> Stop </button>
      <button phx-click="clear_grid">Clear Grid</button>
    </span>

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

    next_gen_tuple = Life.GameServer.run_game(live_cells)

    cells_to_die =
      live_cells
      |> Stream.flat_map(&if(&1 not in next_gen_tuple, do: [&1], else: []))
      |> Enum.map(&convert_tuple_to_id(&1))

    next_gen = Enum.map(next_gen_tuple, &convert_tuple_to_id/1)

    for id <- cells_to_die, do: send_update(CellComponent, id: id, color: "cyan")

    for id <- next_gen, do: send_update(CellComponent, id: id, color: "coral")

    socket = assign(socket, live_cells: next_gen)
    {:noreply, socket}
  end

  def handle_event("start_game", _, socket) do
    {:ok, tref} = :timer.send_interval(@refresh_rate, self(), :tick)
    updated_socket = assign(socket, disabled: "disabled", tref: tref)
    {:noreply, updated_socket}
  end

  def handle_event("stop_game", _, socket) do
    tref = socket.assigns.tref
    :timer.cancel(tref)
    updated_socket = assign(socket, tref: nil, disabled: "")
    {:noreply, updated_socket}
  end

  def handle_event("clear_grid", _, socket) do
    tref = socket.assigns.tref
    :timer.cancel(tref)
    live_cells = socket.assigns.live_cells
    for id <- live_cells, do: send_update(CellComponent, id: id, color: "cyan")
    updated_socket = assign(socket, tref: nil, disabled: "", live_cells: [])
    {:noreply, updated_socket}
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
