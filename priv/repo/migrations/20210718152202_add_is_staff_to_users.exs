defmodule Bytepacked.Repo.Migrations.AddIsStaffToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_staff, :boolean, default: false
    end
  end
end
