defmodule Fiapx.Media.Frame do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "frames" do
    field :image_path, :string
    field :timestamp, :float

    belongs_to :video, Fiapx.Media.Video, type: :binary_id

    timestamps()
  end

  def changeset(frame, attrs) do
    frame
    |> cast(attrs, [:image_path, :timestamp, :video_id])
    |> validate_required([:image_path, :video_id])
    |> assoc_constraint(:video)
  end
end
