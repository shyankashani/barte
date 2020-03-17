defmodule Barte.Repo do
  use Ecto.Repo,
    otp_app: :barte,
    adapter: Ecto.Adapters.Postgres
end
