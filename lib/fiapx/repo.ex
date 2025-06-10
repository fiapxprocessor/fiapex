defmodule Fiapx.Repo do
  use Ecto.Repo,
    otp_app: :fiapx,
    adapter: Ecto.Adapters.Postgres
end
