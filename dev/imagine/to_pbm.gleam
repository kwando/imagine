import gleam/io
import imagine

pub fn main() {
  imagine.from_file("GreatWeekend.png")
  |> imagine.resize_contain(384, 384)
  |> imagine.colorspace(imagine.Gray)
  |> imagine.auto_level
  |> imagine.dither
  |> imagine.colors(2)
  |> imagine.monochrome
  |> debug
  |> imagine.to_file("logo.png")
  |> echo
}

fn debug(image) {
  imagine.to_command(image, "logo.png")
  |> io.println

  image
}
