defmodule Fiapx.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :filename, :string, null: false
      add :content_type, :string
      add :path, :string, null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:videos, [:user_id])
  end
end
