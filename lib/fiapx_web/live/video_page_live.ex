defmodule FiapxWeb.VideoPageLive do
  use FiapxWeb, :live_view

  alias Fiapx.Media.Persistence, as: PersistenceVideo
  alias Fiapx.Handler.Webhooks

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    webhooks =
      case Webhooks.list_webhooks(current_user.id) do
        {:ok, %Tesla.Env{status: 200, body: %{"data" => list}}} -> list
        _ -> []
      end

    socket =
      socket
      |> assign(:uploaded_video_url, nil)
      |> assign(:videos, PersistenceVideo.list_user_videos(current_user.id))
      |> assign(:webhooks, webhooks)
      |> allow_upload(:video,
        accept: ~w(.mp4 .mov .avi),
        max_entries: 3,
        max_file_size: 500_000_000
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= if Enum.empty?(@webhooks) do %>
      <h2 class="text-xl font-semibold mt-8 mb-4">
        Defina aqui o endpoint de notificacao que deseja receber
      </h2>
      <form phx-submit="create_webhook" class="mb-6">
        <input
          type="text"
          name="endpoint"
          placeholder="URL do webhook"
          class="border rounded px-2 py-1 mr-2"
          required
        />
        <button type="submit" class="bg-green-600 text-white px-3 py-1 rounded">Criar Webhook</button>
      </form>
    <% else %>
      <ul class="mb-4">
        <%= for webhook <- @webhooks do %>
          <li class="flex items-center justify-between text-sm text-gray-800 border-b py-2">
            <div>
              <strong>Endpoint:</strong> {webhook["endpoint"]}
            </div>
            <button
              phx-click="delete_webhook"
              phx-value-id={webhook["id"]}
              class="text-red-600 text-sm hover:underline ml-4"
            >
              Deletar
            </button>
          </li>
        <% end %>
      </ul>
    <% end %>

    <div class="max-w-6xl mx-auto mt-10 px-4">
      <h2 class="text-2xl font-bold mb-4">Upload de Vídeo</h2>
      <form id="upload-form" phx-submit="save" phx-change="validate" class="mb-8">
        <p class="text-sm text-gray-600 mb-2">
          Envie no máximo <strong>3 vídeos</strong> com até <strong>500MB</strong> cada.
        </p>
        <.live_file_input upload={@uploads.video} />
        <button type="submit" class="ml-4 px-4 py-2 bg-blue-600 text-white rounded">Upload</button>
      </form>
      <ul>
        <%= for entry <- @uploads.video.entries do %>
          <li>{entry.client_name} (aguardando envio...)</li>
        <% end %>
      </ul>

      <h3 class="text-xl font-semibold mb-4">Seus Vídeos</h3>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
        <%= for video <- @videos do %>
          <div class="bg-white shadow p-4 rounded border">
            <p class="text-sm font-semibold mb-2 break-words">{video.filename}</p>
            <video width="100%" controls class="mb-2">
              <source src={video.path} type={video.content_type} />
              Seu navegador não suporta o elemento de vídeo.
              <p class="text-xs text-gray-500 mb-2">{video.content_type}</p>
            </video>
            <%= if Enum.any?(video.frames) do %>
              <a
                href={"/uploads/zips/#{video.id}.zip"}
                download
                class="text-blue-600 text-sm hover:underline block mt-2"
              >
                Baixar Frames (.zip)
              </a>
            <% else %>
              <p class="text-gray-400 text-sm mt-2">Frames em processamento...</p>
            <% end %>

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
    {:noreply, cancel_upload(socket, :video, ref)}
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
  def handle_event("create_webhook", %{"endpoint" => endpoint}, socket) do
    current_user = socket.assigns.current_user

    case Webhooks.create_webhook(%{
           endpoint: endpoint,
           user_id: current_user.id
         }) do
      {:ok, %Tesla.Env{status: 201}} ->
        updated_webhooks =
          case Webhooks.list_webhooks(current_user.id) do
            {:ok, %Tesla.Env{status: 200, body: %{"data" => list}}} -> list
            _ -> []
          end

        {:noreply,
         socket
         |> put_flash(:info, "Webhook criado com sucesso.")
         |> assign(:webhooks, updated_webhooks)}

      _ ->
        {:noreply, put_flash(socket, :error, "Erro ao criar webhook.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_webhook", _params, socket) do
    current_user = socket.assigns.current_user

    case Webhooks.delete_webhook(current_user.id) do
      {:ok, %Tesla.Env{status: 200}} ->
        updated_webhooks =
          case Webhooks.list_webhooks(current_user.id) do
            {:ok, %Tesla.Env{status: 200, body: %{"data" => list}}} -> list
            _ -> []
          end

        {:noreply,
         socket
         |> put_flash(:info, "Webhook deletado com sucesso.")
         |> assign(:webhooks, updated_webhooks)}

      _ ->
        {:noreply, put_flash(socket, :error, "Erro ao deletar webhook.")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    upload = socket.assigns.uploads.video

    if upload.entries == [] do
      {:noreply,
       socket
       |> assign(:upload_error, "Nenhum vídeo selecionado para upload.")}
    else
      lv_pid = self()

      consume_uploaded_entries(socket, :video, fn %{path: path},
                                                  %{client_name: name, client_type: type} ->
        safe_name =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\-_\.]/, "_")
          |> Path.basename()

        dest = Path.join(["/app/uploads/videos", safe_name])
        File.cp!(path, dest)

        Fiapx.Worker.VideoSupervisor.start_video_job({safe_name, type, socket, lv_pid})
      end)

      {:noreply,
       socket
       |> put_flash(:info, "Vídeos enviados. O processamento será feito em segundo plano.")
       |> assign(:uploaded_video_url, nil)
       |> assign(:upload_error, nil)}
    end
  end

  @impl true
  def handle_info({:video_processed, video}, socket) do
    current_user = socket.assigns.current_user
    videos = PersistenceVideo.list_user_videos(current_user.id)

    {:noreply,
     socket
     |> put_flash(:info, "Vídeo #{video.filename} foi processado com sucesso.")
     |> assign(:videos, videos)}
  end
end
