defmodule Fiapx.Media.Persistence do
  import Ecto.Query, warn: false
  alias Fiapx.Repo

  alias Fiapx.Media.Video

  # Lista todos os vídeos
  def list_videos do
    Repo.all(Video)
  end

  # Lista todos os vídeos de um usuário específico
  def list_user_videos(user_id) do
    from(v in Video, where: v.user_id == ^user_id)
    |> Repo.all()
  end

  # Busca um vídeo por ID (lança erro se não encontrado)
  def get_video!(id), do: Repo.get!(Video, id)

  # Cria um novo vídeo
  def create_video(attrs \\ %{}) do
    %Video{}
    |> Video.changeset(attrs)
    |> Repo.insert()
  end

  # Atualiza um vídeo existente
  def update_video(%Video{} = video, attrs) do
    video
    |> Video.changeset(attrs)
    |> Repo.update()
  end

  # Exclui um vídeo
  def delete_video(video_id) do
    video = Fiapx.Repo.get!(Fiapx.Media.Video, video_id)

    # Apaga o arquivo físico, se existir
    if File.exists?("priv/static" <> video.path) do
      File.rm!("priv/static" <> video.path)
    end

    Fiapx.Repo.delete(video)
  end

  # Retorna um changeset para atualização
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end
end
