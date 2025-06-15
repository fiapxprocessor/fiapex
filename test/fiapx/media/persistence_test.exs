defmodule Fiapx.Media.PersistenceTest do
  use Fiapx.DataCase, async: true

  alias Fiapx.Media.{Persistence, Video, Frame}
  alias Fiapx.Accounts.User
  alias Fiapx.Repo

  describe "list_videos/0" do
    setup do
      user =
        %User{}
        |> User.registration_changeset(%{email: "user@example.com", password: "Teste@123completo"})
        |> Repo.insert!()

      video1 =
        %Video{}
        |> Video.changeset(%{
          filename: "video1.mp4",
          path: "/uploads/video1.mp4",
          user_id: user.id
        })
        |> Repo.insert!()

      video2 =
        %Video{}
        |> Video.changeset(%{
          filename: "video2.mp4",
          path: "/uploads/video2.mp4",
          user_id: user.id
        })
        |> Repo.insert!()

      {:ok, user: user, videos: [video1, video2]}
    end

    test "retorna todos os vídeos existentes", %{videos: [video1, video2]} do
      result = Persistence.list_videos()

      assert length(result) == 2
      assert Enum.any?(result, &(&1.id == video1.id))
      assert Enum.any?(result, &(&1.id == video2.id))
    end
  end

  describe "list_user_videos/1" do
    setup do
      user1 =
        %User{}
        |> User.registration_changeset(%{
          email: "user1@example.com",
          password: "Teste@123completo"
        })
        |> Repo.insert!()

      user2 =
        %User{}
        |> User.registration_changeset(%{
          email: "user2@example.com",
          password: "Teste@123completo"
        })
        |> Repo.insert!()

      video1 =
        %Video{}
        |> Video.changeset(%{
          filename: "video1.mp4",
          path: "/uploads/video1.mp4",
          user_id: user1.id
        })
        |> Repo.insert!()

      video2 =
        %Video{}
        |> Video.changeset(%{
          filename: "video2.mp4",
          path: "/uploads/video2.mp4",
          user_id: user1.id
        })
        |> Repo.insert!()

      _video3 =
        %Video{}
        |> Video.changeset(%{
          filename: "video3.mp4",
          path: "/uploads/video3.mp4",
          user_id: user2.id
        })
        |> Repo.insert!()

      for {video, filenames} <- [{video1, ["frame1.png", "frame2.png"]}, {video2, ["frame3.png"]}],
          filename <- filenames do
        %Frame{}
        |> Frame.changeset(%{image_path: "/uploads/frames/#{filename}", video_id: video.id})
        |> Repo.insert!()
      end

      {:ok, user1: user1}
    end

    test "retorna apenas vídeos do usuário e pré-carrega os frames", %{user1: user1} do
      result = Persistence.list_user_videos(user1.id)

      assert length(result) == 2
      assert Enum.all?(result, &(&1.user_id == user1.id))
      assert Enum.any?(result, &(length(&1.frames) > 0))
    end
  end

  describe "Persistence vídeo CRUD e frames" do
    setup do
      user =
        %User{}
        |> User.registration_changeset(%{email: "user@example.com", password: "Teste@123completo"})
        |> Repo.insert!()

      video =
        %Video{}
        |> Video.changeset(%{filename: "video.mp4", path: "/uploads/video.mp4", user_id: user.id})
        |> Repo.insert!()

      {:ok, user: user, video: video}
    end

    test "get_video/1 retorna vídeo por id", %{video: video} do
      found = Persistence.get_video(video.id)
      assert found.id == video.id
    end

    test "create_video/1 cria um novo vídeo", %{user: user} do
      attrs = %{
        filename: "new_video.mp4",
        path: "/uploads/new_video.mp4",
        user_id: user.id
      }

      assert {:ok, %Video{} = video} = Persistence.create_video(attrs)
      assert video.filename == "new_video.mp4"
    end

    test "update_video/2 atualiza um vídeo existente", %{video: video} do
      updated_attrs = %{filename: "updated_video.mp4"}

      assert {:ok, %Video{} = updated} = Persistence.update_video(video, updated_attrs)
      assert updated.filename == "updated_video.mp4"
    end

    test "delete_video/1 remove vídeo e arquivo, se existir", %{video: video} do
      path = "priv/static/videos#{video.path}"
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "conteúdo de teste")

      assert File.exists?(path)

      assert {:ok, _deleted} = Persistence.delete_video(video.id)

      refute File.exists?(path)
      refute Repo.get(Video, video.id)
    end

    test "change_video/2 retorna changeset válido", %{video: video} do
      changeset = Persistence.change_video(video, %{filename: "changed.mp4"})
      assert changeset.valid?
      assert changeset.changes.filename == "changed.mp4"
    end

    test "list_frames/1 retorna frames do vídeo", %{video: video} do
      frame1 =
        %Frame{} |> Frame.changeset(%{image_path: "f1.png", video_id: video.id}) |> Repo.insert!()

      frame2 =
        %Frame{} |> Frame.changeset(%{image_path: "f2.png", video_id: video.id}) |> Repo.insert!()

      result = Persistence.list_frames(video.id)
      assert length(result) == 2
      assert Enum.any?(result, &(&1.id == frame1.id))
      assert Enum.any?(result, &(&1.id == frame2.id))
    end

    test "save_frames/2 salva imagens como frames e cria zip", %{video: video} do
      frames_path = "uploads/frames/#{video.id}"
      File.mkdir_p!(frames_path)

      File.write!(Path.join(frames_path, "frame1.png"), "fake-image-1")
      File.write!(Path.join(frames_path, "frame2.png"), "fake-image-2")

      assert [] == Repo.all(Frame)

      Persistence.save_frames(video.id, frames_path)

      frames = Repo.all(Frame)
      assert length(frames) == 2
      assert File.exists?("uploads/zips/#{video.id}.zip")
    end
  end
end
