defmodule Fiapx.Media.FrameExtractor do
  import FFmpex
  use FFmpex.Options

  def extract_frames(%{
        input_video: input_path,
        output_path: output_path
      }) do
    File.mkdir_p!(output_path)

    output_pattern = Path.join(output_path, "frame_%04d.jpg")

    command =
      FFmpex.new_command()
      |> add_input_file(input_path)
      |> add_output_file(output_pattern)
      |> add_file_option(option_r(1))
      |> add_file_option(option_qscale(2))
      |> add_file_option(option_f("image2"))

    FFmpex.execute(command)
  end
end
