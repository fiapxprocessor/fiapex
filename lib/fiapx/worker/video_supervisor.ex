defmodule Fiapx.Worker.VideoSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_video_job(args) do
    spec = {Fiapx.Worker.VideoWorker, args}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
