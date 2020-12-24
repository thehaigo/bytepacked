defmodule Bytepacked.Repo do
  use Ecto.Repo,
    otp_app: :bytepacked,
    adapter: Ecto.Adapters.Postgres
end
