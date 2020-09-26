defmodule GameOfLife.Repo do
  use Ecto.Repo,
    otp_app: :game_of_life,
    adapter: Ecto.Adapters.Postgres
end
