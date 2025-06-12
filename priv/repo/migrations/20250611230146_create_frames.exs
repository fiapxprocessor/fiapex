defmodule Fiapx.Repo.Migrations.CreateFrames do
  use Ecto.Migration

  def change do
    create table(:frames, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :image_path, :string, null: false
      add :timestamp, :float
      add :video_id, references(:videos, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:frames, [:video_id])
  end
end
