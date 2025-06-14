defmodule Fiapx.Worker.VideoWorker do
  use Task

  def start_link({name, type, socket, liv_pid}) do
    Task.start_link(fn ->
      Fiapx.Worker.VideoProcessor.process({name, type, socket, liv_pid})
    end)
  end
end
