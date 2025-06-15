defmodule Fiapx.Media.FrameExtractorTest do
  use ExUnit.Case, async: true
  import ExUnit.Assertions

  alias Fiapx.Media.FrameExtractor

  @sample_video "test/support/sample_video.mp4"

  setup do
    output_path = Path.join(System.tmp_dir!(), "frames_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(output_path)
    {:ok, output_path: output_path}
  end

  test "extract_frames/1 extrai frames com sucesso", %{output_path: output_path} do
    assert File.exists?(@sample_video)

    result =
      FrameExtractor.extract_frames(%{
        input_video: @sample_video,
        output_path: output_path
      })

    assert result == {:ok, ""}

    # Verifica se ao menos um frame foi criado
    frames =
      output_path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".jpg"))

    assert length(frames) > 0
  end
end
