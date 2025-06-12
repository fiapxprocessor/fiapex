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
  def get_video(id), do: Repo.get(Video, id)

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

    if File.exists?("priv/static/videos" <> video.path) do
      File.rm!("priv/static/videos" <> video.path)
    end

    Fiapx.Repo.delete(video)
  end

  # Retorna um changeset para atualização
  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  def save_frames(video_id, frames_path) do
    frames =
      File.ls!(frames_path)
      |> Enum.map(fn filename ->
        %{
          image_path: Path.join(frames_path, filename),
          video_id: video_id
        }
      end)

    Enum.each(frames, fn data ->
      Repo.insert!(Fiapx.Media.Frame.changeset(%Fiapx.Media.Frame{}, data))
    end)

    zip_path = Path.join(["uploads/zips", "#{video_id}.zip"]) |> String.to_charlist()
    frame_path = Path.join(["uploads/frames", "#{video_id}"]) |> String.to_charlist()

    filenames =
      File.ls!("uploads/frames/#{video_id}")
      |> Enum.map( fn frame ->
        String.to_charlist(frame)
      end)

    :zip.create(zip_path,
      filenames,
      cwd: frame_path
    )
  end
end
