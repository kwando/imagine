import alakazam/image
import gleam/io
import gleam_community/colour

pub fn main() {
  image.from_file("GreatWeekend.png")
  //|> perpare_for_printing

  //|> alakazam.auto_level
  //|> alakazam.contrast_stretch(2.0, 2.0)
  //|> alakazam.dither
  //|> alakazam.colors(8)
  //|> alakazam.raw("-segment", "1")
  //|> alakazam.raw("-normalize", "")
  //|> alakazam.sepia(95.0)

  //|> alakazam.dither
  //|> alakazam.posterize(4)

  |> image.background(colour.black)
  |> image.rotate(22.0)
  |> debug
  |> image.to_file("logo.png")
  |> echo
}

pub fn perpare_for_printing(image) {
  image
  |> image.resize_contain(384, 384)
  |> image.colorspace(image.Gray)
  |> image.auto_level
  |> image.dither
  |> image.colors(2)
  |> image.monochrome
}

fn debug(image) {
  image.to_command(image, "logo.png")
  |> io.println

  image
}
