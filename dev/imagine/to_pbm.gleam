import gleam/io
import gleam_community/colour
import imagine

pub fn main() {
  imagine.from_file("GreatWeekend.png")
  //|> perpare_for_printing

  //|> imagine.auto_level
  //|> imagine.contrast_stretch(2.0, 2.0)
  //|> imagine.dither
  //|> imagine.colors(8)
  //|> imagine.raw("-segment", "1")
  //|> imagine.raw("-normalize", "")
  //|> imagine.sepia(95.0)

  //|> imagine.dither
  //|> imagine.posterize(4)

  |> imagine.background(colour.black)
  |> imagine.rotate(22.0)
  |> debug
  |> imagine.to_file("logo.png")
  |> echo
}

pub fn perpare_for_printing(image) {
  image
  |> imagine.resize_contain(384, 384)
  |> imagine.colorspace(imagine.Gray)
  |> imagine.auto_level
  |> imagine.dither
  |> imagine.colors(2)
  |> imagine.monochrome
}

fn debug(image) {
  imagine.to_command(image, "logo.png")
  |> io.println

  image
}
