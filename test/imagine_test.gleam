import gleam_community/colour
import gleeunit
import imagine
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn identify_reads_image_info_test() {
  let assert Ok(info) = imagine.identify("test/fixtures/logo.png")
  assert info.format == imagine.Png
  assert info.width == 640
  assert info.height == 480
  assert info.colorspace == imagine.Srgb
  assert info.depth == 8
  assert info.has_alpha == False
  assert info.file_size > 0
}

pub fn identify_reads_jpeg_test() {
  let assert Ok(info) = imagine.identify("test/fixtures/rose.jpg")
  assert info.format == imagine.Jpeg
  assert info.width == 70
  assert info.height == 46
  assert info.colorspace == imagine.Srgb
  assert info.depth == 8
  assert info.has_alpha == False
  assert info.file_size > 0
}

pub fn identify_fails_for_nonexistent_file_test() {
  case imagine.identify("test/fixtures/does_not_exist.png") {
    Error(imagine.CommandFailed(_, _)) -> Nil
    _ -> panic as "Should return CommandFailed error for non-existent file"
  }
}

pub fn resize_changes_dimensions_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize(imagine.Fit(100, 100))
    |> imagine.to_file("test/output/resized.png")

  let assert Ok(info) = imagine.identify("test/output/resized.png")
  assert info.format == imagine.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn format_conversion_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.to_file("test/output/converted.jpg")

  let assert Ok(info) = imagine.identify("test/output/converted.jpg")
  assert info.format == imagine.Jpeg
}

pub fn chain_multiple_operations_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize(imagine.Fit(200, 200))
    |> imagine.blur(1.0)
    |> imagine.monochrome()
    |> imagine.to_file("test/output/chained.png")

  let assert Ok(info) = imagine.identify("test/output/chained.png")
  assert info.format == imagine.Png
  assert info.width == 200
  assert info.height == 150
}

pub fn dither_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize(imagine.Fit(100, 100))
    |> imagine.dither()
    |> imagine.colors(4)
    |> imagine.to_file("test/output/dithered.png")

  let assert Ok(info) = imagine.identify("test/output/dithered.png")
  assert info.format == imagine.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn posterize_with_dither_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize(imagine.Fit(100, 100))
    |> imagine.dither()
    |> imagine.posterize(4)
    |> imagine.to_file("test/output/posterized_dither.png")

  let assert Ok(info) = imagine.identify("test/output/posterized_dither.png")
  assert info.format == imagine.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn posterize_without_dither_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize(imagine.Fit(100, 100))
    |> imagine.posterize(4)
    |> imagine.to_file("test/output/posterized_nodither.png")

  let assert Ok(info) = imagine.identify("test/output/posterized_nodither.png")
  assert info.format == imagine.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn crop_width_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.gravity(imagine.Center)
    |> imagine.crop_width(200)
    |> imagine.to_file("test/output/cropped.png")

  let assert Ok(info) = imagine.identify("test/output/cropped.png")
  assert info.format == imagine.Png
  assert info.width == 200
}

pub fn to_bits_returns_data_test() {
  let assert Ok(bits) =
    imagine.from_file("test/fixtures/rose.jpg")
    |> imagine.resize(imagine.Fit(50, 50))
    |> imagine.to_bits(imagine.Png)

  // Write bits to temporary file and verify it's a valid image
  let temp_file = "test/output/to_bits.png"
  let assert Ok(_) = simplifile.write_bits(bits, to: temp_file)

  let assert Ok(info) = imagine.identify(temp_file)
  assert info.format == imagine.Png
  // Aspect ratio is preserved, so height will be 33 not 50
  assert info.width == 50
  assert info.height == 33
}

pub fn resize_contain_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize_contain(200, 200)
    |> imagine.to_file("test/output/contain.png")

  let assert Ok(info) = imagine.identify("test/output/contain.png")
  assert info.format == imagine.Png
  // Aspect ratio preserved, so it fits within 200x200
  assert info.width == 200
  assert info.height == 150
}

pub fn resize_cover_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize_cover(200, 200, imagine.Center)
    |> imagine.to_file("test/output/cover.png")

  let assert Ok(info) = imagine.identify("test/output/cover.png")
  assert info.format == imagine.Png
  // Exact dimensions because of extent
  assert info.width == 200
  assert info.height == 200
}

pub fn resize_fill_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize_fill(200, 200)
    |> imagine.to_file("test/output/fill.png")

  let assert Ok(info) = imagine.identify("test/output/fill.png")
  assert info.format == imagine.Png
  // Exact dimensions, aspect ratio ignored
  assert info.width == 200
  assert info.height == 200
}

pub fn flop_mirrors_horizontally_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.flop()
    |> imagine.to_file("test/output/flopped.png")

  let assert Ok(info) = imagine.identify("test/output/flopped.png")
  assert info.format == imagine.Png
  // Dimensions should remain the same
  assert info.width == 640
  assert info.height == 480
}

pub fn sharpen_applies_sharpening_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.sharpen(0.0)
    |> imagine.to_file("test/output/sharpened.png")

  let assert Ok(info) = imagine.identify("test/output/sharpened.png")
  assert info.format == imagine.Png
  // Dimensions should remain the same
  assert info.width == 640
  assert info.height == 480
}

pub fn strip_removes_metadata_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/rose.jpg")
    |> imagine.strip()
    |> imagine.to_file("test/output/stripped.jpg")

  let assert Ok(info) = imagine.identify("test/output/stripped.jpg")
  assert info.format == imagine.Jpeg
  // Dimensions should remain the same
  assert info.width == 70
  assert info.height == 46
}

pub fn thumbnail_creates_resized_preview_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.thumbnail(100, 100)
    |> imagine.to_file("test/output/thumbnail.png")

  let assert Ok(info) = imagine.identify("test/output/thumbnail.png")
  assert info.format == imagine.Png
  // Should fit within 100x100 while preserving aspect ratio
  assert info.width == 100
  assert info.height == 75
}

pub fn filter_changes_resampling_algorithm_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.filter(imagine.Nearest)
    |> imagine.resize_contain(100, 100)
    |> imagine.to_file("test/output/filtered.png")

  let assert Ok(info) = imagine.identify("test/output/filtered.png")
  assert info.format == imagine.Png
  // Should resize successfully with nearest neighbor filter
  assert info.width == 100
  assert info.height == 75
}

pub fn from_bits_round_trip_test() {
  // Read image file as bytes
  let assert Ok(bits) = simplifile.read_bits("test/fixtures/logo.png")

  // Create image from bytes and process
  let assert Ok(_) =
    imagine.from_bits(bits)
    |> imagine.resize_contain(100, 100)
    |> imagine.to_file("test/output/from_bits.png")

  // Verify the output
  let assert Ok(info) = imagine.identify("test/output/from_bits.png")
  assert info.format == imagine.Png
  assert info.width == 100
  assert info.height == 75
}

// Command generation tests

pub fn contrast_stretch_command_test() {
  let command =
    imagine.from_file("input.jpg")
    |> imagine.contrast_stretch(2.5, 1.0)
    |> imagine.to_command("output.jpg")

  assert command == "magick input.jpg -contrast-stretch 2.5%x1.0% output.jpg"
}

pub fn background_colour_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.background(colour.red)
    |> imagine.to_command("output.png")

  assert command == "magick input.png -background CC0000 output.png"
}

pub fn extent_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.extent(200, 150)
    |> imagine.to_command("output.png")

  assert command == "magick input.png -extent 200x150 output.png"
}

pub fn gravity_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.gravity(imagine.Center)
    |> imagine.crop_width(100)
    |> imagine.to_command("output.png")

  assert command
    == "magick input.png -gravity center -crop 100x0+0+0 +repage output.png"
}

pub fn resize_fit_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.resize(imagine.Fit(100, 200))
    |> imagine.to_command("output.png")

  assert command == "magick input.png -resize 100x200 output.png"
}

pub fn resize_fill_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.resize(imagine.Fill(100, 200))
    |> imagine.to_command("output.png")

  assert command == "magick input.png -resize 100x200^ output.png"
}

pub fn resize_exact_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.resize(imagine.Exact(100, 200))
    |> imagine.to_command("output.png")

  assert command == "magick input.png -resize 100x200! output.png"
}

pub fn multiple_operations_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.resize(imagine.Fit(100, 100))
    |> imagine.flip()
    |> imagine.strip()
    |> imagine.to_command("output.png")

  assert command == "magick input.png -resize 100x100 -flip -strip output.png"
}

pub fn simple_flags_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.auto_orient()
    |> imagine.auto_level()
    |> imagine.negate()
    |> imagine.to_command("output.png")

  assert command
    == "magick input.png -auto-orient -auto-level -negate output.png"
}

pub fn alpha_extract_command_test() {
  let command =
    imagine.from_file("input.png")
    |> imagine.alpha_to_image()
    |> imagine.to_command("output.png")

  assert command == "magick input.png -alpha extract output.png"
}
