defmodule FiapxWeb.VideoPageLive do
  use FiapxWeb, :live_view

  alias Fiapx.Media.Persistence, as: PersistenceVideo

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

      socket =
        socket
        |> assign(:uploaded_video_url, nil)
        |> assign(:videos, PersistenceVideo.list_user_videos(current_user.id))
        |> allow_upload(:video,
          accept: ~w(.mp4 .mov .avi),
          max_entries: 1,
          max_file_size: 100_000_000
        )

      {:ok, socket}
    end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto mt-10 px-4">
      <h2 class="text-2xl font-bold mb-4">Upload de Vídeo</h2>

      <form id="upload-form" phx-submit="save" phx-change="validate" class="mb-8">
        <.live_file_input upload={@uploads.video} />
        <button type="submit" class="ml-4 px-4 py-2 bg-blue-600 text-white rounded">Upload</button>
      </form>

      <h3 class="text-xl font-semibold mb-4">Seus Vídeos</h3>

      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
        <%= for video <- @videos do %>
          <div class="bg-white shadow p-4 rounded border">
            <p class="text-sm font-semibold mb-2 break-words"><%= video.filename %></p>
            <video width="100%" controls class="mb-2">
              <source src={video.path} type={video.content_type}>
              Seu navegador não suporta o elemento de vídeo.
            <p class="text-xs text-gray-500 mb-2"><%= video.content_type %></p>

            </video>
              <a
                href={"/uploads/zips/#{video.id}.zip"}
                download
                class="text-blue-600 text-sm hover:underline block mt-2"
              >
                Baixar Frames (.zip)
              </a>

            <button
              type="button"
              phx-click="delete_video"
              phx-value-id={video.id}
              class="text-red-600 text-sm hover:underline"
            >
              Deletar vídeo
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end


  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_video", %{"id" => video_id}, socket) do
    case PersistenceVideo.get_video(video_id) do
      nil ->
        {:noreply, socket}


      video ->
        file_path = Path.join(["/app", video.path])
        if File.exists?(file_path), do: File.rm(file_path)

        frames_dir = Path.join(["/app/uploads/frames", video.id])
        if File.dir?(frames_dir), do: File.rm_rf!(frames_dir)

        zip_path = Path.join(["/app/uploads/zips", "#{video.id}.zip"])
        if File.exists?(zip_path), do: File.rm_rf!(zip_path)

        PersistenceVideo.delete_video(video_id)

        current_user = socket.assigns.current_user
        videos = PersistenceVideo.list_user_videos(current_user.id)

        {:noreply, assign(socket, :videos, videos)}
    end
  end

 @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    upload = socket.assigns.uploads.video

    case List.first(upload.entries) do
      nil ->
        {:noreply,
        socket
        |> assign(:upload_error, "Nenhum vídeo selecionado para upload.")}

      entry ->
        name =
          entry.client_name
            |> String.downcase()
            |> String.replace(~r/[^a-z0-9\-_\.]/, "_")
            |> Path.basename()

        type = entry.client_type

        uploaded_paths =
          consume_uploaded_entries(socket, :video, fn %{path: path}, _meta ->
            dest = Path.join(["/app/uploads/videos", name])
            Path.dirname(dest)
            File.cp!(path, dest)

            url_path = "/uploads/videos/#{name}"

            current_user = socket.assigns.current_user

            {:ok, video} =
              PersistenceVideo.create_video(%{
                filename: name,
                content_type: type,
                path: url_path,
                user_id: current_user.id
              })

            absolute_input_path = Path.join(["/app/uploads/videos", name])
            frames_output_dir = Path.join(["/app/uploads/frames", video.id])
            File.mkdir_p!(frames_output_dir)

            Fiapx.Media.FrameExtractor.extract_frames(%{
              input_video: absolute_input_path,
              output_path: frames_output_dir
            })

            PersistenceVideo.save_frames(video.id, frames_output_dir)

            {:ok, url_path}
          end)

        current_user = socket.assigns.current_user
        videos = PersistenceVideo.list_user_videos(current_user.id)

        {:noreply,
        socket
        |> assign(:uploaded_video_url, List.first(uploaded_paths))
        |> assign(:videos, videos)
        |> assign(:upload_error, nil)}
    end
  end
end
