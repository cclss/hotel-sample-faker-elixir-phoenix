defmodule Fakr.Repo do
  use Ecto.Repo,
    otp_app: :fakr,
    adapter: Ecto.Adapters.Postgres
end
