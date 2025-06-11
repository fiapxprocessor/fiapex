defmodule Fiapx.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :filename, :string, null: false
      add :content_type, :string
      add :path, :string, null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:videos, [:user_id])
  end
end
