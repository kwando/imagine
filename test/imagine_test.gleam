import gleam/string
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

pub fn crop_width_test() {
  let assert Ok(_) =
    imagine.from_file("test/fixtures/logo.png")
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
  let temp_file = "test/output/from_bits.png"
  let assert Ok(_) = simplifile.write_bits(bits, to: temp_file)

  let assert Ok(info) = imagine.identify(temp_file)
  assert info.format == imagine.Png
  // Aspect ratio is preserved, so height will be 33 not 50
  assert info.width == 50
  assert info.height == 33
}

pub fn resize_contain_test() {
  // CSS contain: entire image visible, may have empty space
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
  // CSS cover: fills entire box, may crop
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
  // CSS fill: stretch to fill, ignore aspect ratio
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

pub fn to_command_returns_magick_command_string_test() {
  let command =
    imagine.from_file("test/fixtures/logo.png")
    |> imagine.resize_contain(100, 100)
    |> imagine.to_command("output.png")

  // Command should start with "magick" and contain the input file and operations
  assert string.starts_with(command, "magick ")
  assert string.contains(command, "test/fixtures/logo.png")
  assert string.contains(command, "-resize")
  assert string.contains(command, "output.png")
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
