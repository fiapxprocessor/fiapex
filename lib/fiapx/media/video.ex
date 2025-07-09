defmodule Fiapx.Media.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "videos" do
    field :filename, :string
    field :content_type, :string
    field :path, :string

    has_many :frames, Fiapx.Media.Frame
    belongs_to :user, Fiapx.Accounts.User, type: :binary_id

    timestamps()
  end

  def changeset(video, attrs) do
    video
    |> cast(attrs, [:filename, :content_type, :path, :user_id])
    |> validate_required([:filename, :path, :user_id])
    |> assoc_constraint(:user)
  end
end
