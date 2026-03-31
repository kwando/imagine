import alakazam/image
import envoy
import gleam_community/colour
import gleeunit
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn identify_reads_image_info_test() {
  let assert Ok(info) = image.identify("test/fixtures/logo.png")
  assert info.format == image.Png
  assert info.width == 640
  assert info.height == 480
  assert info.colorspace == image.Srgb
  assert info.depth == 8
  assert info.has_alpha == False
  assert info.file_size > 0
}

pub fn identify_reads_jpeg_test() {
  let assert Ok(info) = image.identify("test/fixtures/rose.jpg")
  assert info.format == image.Jpeg
  assert info.width == 70
  assert info.height == 46
  assert info.colorspace == image.Srgb
  assert info.depth == 8
  assert info.has_alpha == False
  assert info.file_size > 0
}

pub fn identify_fails_for_nonexistent_file_test() {
  case image.identify("test/fixtures/does_not_exist.png") {
    Error(image.CommandFailed(_, _)) -> Nil
    _ -> panic as "Should return CommandFailed error for non-existent file"
  }
}

pub fn resize_changes_dimensions_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize(image.Fit(100, 100))
    |> image.to_file("test/output/resized.png")

  let assert Ok(info) = image.identify("test/output/resized.png")
  assert info.format == image.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn format_conversion_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.to_file("test/output/converted.jpg")

  let assert Ok(info) = image.identify("test/output/converted.jpg")
  assert info.format == image.Jpeg
}

pub fn chain_multiple_operations_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize(image.Fit(200, 200))
    |> image.blur(1.0)
    |> image.monochrome()
    |> image.to_file("test/output/chained.png")

  let assert Ok(info) = image.identify("test/output/chained.png")
  assert info.format == image.Png
  assert info.width == 200
  assert info.height == 150
}

pub fn dither_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize(image.Fit(100, 100))
    |> image.dither()
    |> image.colors(4)
    |> image.to_file("test/output/dithered.png")

  let assert Ok(info) = image.identify("test/output/dithered.png")
  assert info.format == image.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn posterize_with_dither_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize(image.Fit(100, 100))
    |> image.dither()
    |> image.posterize(4)
    |> image.to_file("test/output/posterized_dither.png")

  let assert Ok(info) = image.identify("test/output/posterized_dither.png")
  assert info.format == image.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn posterize_without_dither_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize(image.Fit(100, 100))
    |> image.posterize(4)
    |> image.to_file("test/output/posterized_nodither.png")

  let assert Ok(info) = image.identify("test/output/posterized_nodither.png")
  assert info.format == image.Png
  assert info.width == 100
  assert info.height == 75
}

pub fn crop_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.crop(100, 50, 200, 150)
    |> image.to_file("test/output/cropped.png")

  let assert Ok(info) = image.identify("test/output/cropped.png")
  assert info.format == image.Png
  assert info.width == 200
  assert info.height == 150
}

pub fn to_bits_returns_data_test() {
  let assert Ok(bits) =
    image.from_file("test/fixtures/rose.jpg")
    |> image.resize(image.Fit(50, 50))
    |> image.to_bits(image.Png)

  // Write bits to temporary file and verify it's a valid image
  let temp_file = "test/output/to_bits.png"
  let assert Ok(_) = simplifile.write_bits(bits, to: temp_file)

  let assert Ok(info) = image.identify(temp_file)
  assert info.format == image.Png
  // Aspect ratio is preserved, so height will be 33 not 50
  assert info.width == 50
  assert info.height == 33
}

pub fn resize_contain_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize_contain(200, 200)
    |> image.to_file("test/output/contain.png")

  let assert Ok(info) = image.identify("test/output/contain.png")
  assert info.format == image.Png
  // Aspect ratio preserved, so it fits within 200x200
  assert info.width == 200
  assert info.height == 150
}

pub fn resize_cover_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize_cover(200, 200, image.Center)
    |> image.to_file("test/output/cover.png")

  let assert Ok(info) = image.identify("test/output/cover.png")
  assert info.format == image.Png
  // Exact dimensions because of extent
  assert info.width == 200
  assert info.height == 200
}

pub fn resize_fill_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.resize_fill(200, 200)
    |> image.to_file("test/output/fill.png")

  let assert Ok(info) = image.identify("test/output/fill.png")
  assert info.format == image.Png
  // Exact dimensions, aspect ratio ignored
  assert info.width == 200
  assert info.height == 200
}

pub fn flop_mirrors_horizontally_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.flop()
    |> image.to_file("test/output/flopped.png")

  let assert Ok(info) = image.identify("test/output/flopped.png")
  assert info.format == image.Png
  // Dimensions should remain the same
  assert info.width == 640
  assert info.height == 480
}

pub fn sharpen_applies_sharpening_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.sharpen(0.0)
    |> image.to_file("test/output/sharpened.png")

  let assert Ok(info) = image.identify("test/output/sharpened.png")
  assert info.format == image.Png
  // Dimensions should remain the same
  assert info.width == 640
  assert info.height == 480
}

pub fn strip_removes_metadata_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/rose.jpg")
    |> image.strip()
    |> image.to_file("test/output/stripped.jpg")

  let assert Ok(info) = image.identify("test/output/stripped.jpg")
  assert info.format == image.Jpeg
  // Dimensions should remain the same
  assert info.width == 70
  assert info.height == 46
}

pub fn thumbnail_creates_resized_preview_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.thumbnail(100, 100)
    |> image.to_file("test/output/thumbnail.png")

  let assert Ok(info) = image.identify("test/output/thumbnail.png")
  assert info.format == image.Png
  // Should fit within 100x100 while preserving aspect ratio
  assert info.width == 100
  assert info.height == 75
}

pub fn filter_changes_resampling_algorithm_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.filter(image.Nearest)
    |> image.resize_contain(100, 100)
    |> image.to_file("test/output/filtered.png")

  let assert Ok(info) = image.identify("test/output/filtered.png")
  assert info.format == image.Png
  // Should resize successfully with nearest neighbor filter
  assert info.width == 100
  assert info.height == 75
}

pub fn from_bits_round_trip_test() {
  // Read image file as bytes
  let assert Ok(bits) = simplifile.read_bits("test/fixtures/logo.png")

  // Create image from bytes and process
  let assert Ok(_) =
    image.from_bits(bits)
    |> image.resize_contain(100, 100)
    |> image.to_file("test/output/from_bits.png")

  // Verify the output
  let assert Ok(info) = image.identify("test/output/from_bits.png")
  assert info.format == image.Png
  assert info.width == 100
  assert info.height == 75
}

// Command generation tests

pub fn contrast_stretch_command_test() {
  let command =
    image.from_file("input.jpg")
    |> image.contrast_stretch(2.5, 1.0)
    |> image.to_command("output.jpg")

  assert command == "magick input.jpg -contrast-stretch 2.5%x1.0% output.jpg"
}

pub fn background_colour_command_test() {
  let command =
    image.from_file("input.png")
    |> image.background(colour.red)
    |> image.to_command("output.png")

  assert command == "magick input.png -background #CC0000 output.png"
}

pub fn extent_command_test() {
  let command =
    image.from_file("input.png")
    |> image.extent(200, 150)
    |> image.to_command("output.png")

  assert command == "magick input.png -extent 200x150 output.png"
}

pub fn crop_command_test() {
  let command =
    image.from_file("input.png")
    |> image.crop(10, 20, 100, 200)
    |> image.to_command("output.png")

  assert command == "magick input.png -crop 100x200+10+20 +repage output.png"
}

pub fn resize_fit_command_test() {
  let command =
    image.from_file("input.png")
    |> image.resize(image.Fit(100, 200))
    |> image.to_command("output.png")

  assert command == "magick input.png -resize 100x200 output.png"
}

pub fn resize_fill_command_test() {
  let command =
    image.from_file("input.png")
    |> image.resize(image.Fill(100, 200))
    |> image.to_command("output.png")

  assert command == "magick input.png -resize 100x200^ output.png"
}

pub fn resize_exact_command_test() {
  let command =
    image.from_file("input.png")
    |> image.resize(image.Exact(100, 200))
    |> image.to_command("output.png")

  assert command == "magick input.png -resize 100x200! output.png"
}

pub fn multiple_operations_command_test() {
  let command =
    image.from_file("input.png")
    |> image.resize(image.Fit(100, 100))
    |> image.flip()
    |> image.strip()
    |> image.to_command("output.png")

  assert command == "magick input.png -resize 100x100 -flip -strip output.png"
}

pub fn simple_flags_command_test() {
  let command =
    image.from_file("input.png")
    |> image.auto_orient()
    |> image.auto_level()
    |> image.negate()
    |> image.to_command("output.png")

  assert command
    == "magick input.png -auto-orient -auto-level -negate output.png"
}

pub fn alpha_extract_command_test() {
  let command =
    image.from_file("input.png")
    |> image.alpha_to_image()
    |> image.to_command("output.png")

  assert command == "magick input.png -alpha extract output.png"
}

pub fn rotate_command_test() {
  let command =
    image.from_file("input.png")
    |> image.rotate(90.0)
    |> image.to_command("output.png")

  assert command == "magick input.png -rotate 90.0 output.png"
}

pub fn rotate_negative_command_test() {
  let command =
    image.from_file("input.png")
    |> image.rotate(-45.0)
    |> image.to_command("output.png")

  assert command == "magick input.png -rotate -45.0 output.png"
}

pub fn quality_command_test() {
  let command =
    image.from_file("input.png")
    |> image.quality(85)
    |> image.to_command("output.jpg")

  assert command == "magick input.png -quality 85 output.jpg"
}

pub fn brightness_contrast_command_test() {
  let command =
    image.from_file("input.png")
    |> image.brightness_contrast(10, 20)
    |> image.to_command("output.png")

  assert command == "magick input.png -brightness-contrast 10x20 output.png"
}

pub fn brightness_contrast_negative_test() {
  let command =
    image.from_file("input.png")
    |> image.brightness_contrast(-10, -5)
    |> image.to_command("output.png")

  assert command == "magick input.png -brightness-contrast -10x-5 output.png"
}

pub fn gamma_command_test() {
  let command =
    image.from_file("input.png")
    |> image.gamma(1.5)
    |> image.to_command("output.png")

  assert command == "magick input.png -gamma 1.5 output.png"
}

pub fn gamma_less_than_one_command_test() {
  let command =
    image.from_file("input.png")
    |> image.gamma(0.7)
    |> image.to_command("output.png")

  assert command == "magick input.png -gamma 0.7 output.png"
}

pub fn rotate_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.rotate(90.0)
    |> image.to_file("test/output/rotated.png")

  let assert Ok(info) = image.identify("test/output/rotated.png")
  assert info.format == image.Png
  assert info.height == 640
  assert info.width == 480
}

pub fn quality_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.quality(50)
    |> image.to_file("test/output/low_quality.jpg")

  let assert Ok(info) = image.identify("test/output/low_quality.jpg")
  assert info.format == image.Jpeg
}

pub fn brightness_contrast_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.brightness_contrast(20, 30)
    |> image.to_file("test/output/adjusted.png")

  let assert Ok(info) = image.identify("test/output/adjusted.png")
  assert info.format == image.Png
}

pub fn gamma_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.gamma(1.5)
    |> image.to_file("test/output/gamma.png")

  let assert Ok(info) = image.identify("test/output/gamma.png")
  assert info.format == image.Png
}

pub fn webp_format_command_test() {
  let command =
    image.from_file("input.png")
    |> image.to_command("output.webp")

  assert command == "magick input.png output.webp"
}

pub fn webp_format_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.to_file("test/output/logo.webp")

  let assert Ok(info) = image.identify("test/output/logo.webp")
  assert info.format == image.Webp
}

pub fn sepia_command_test() {
  let command =
    image.from_file("input.png")
    |> image.sepia(80.0)
    |> image.to_command("output.png")

  assert command == "magick input.png -sepia-tone 80.0% output.png"
}

pub fn sepia_test() {
  let assert Ok(_) =
    image.from_file("test/fixtures/logo.png")
    |> image.sepia(80.0)
    |> image.to_file("test/output/sepia.png")

  let assert Ok(info) = image.identify("test/output/sepia.png")
  assert info.format == image.Png
}

pub fn policy_test() {
  let assert Ok(default_policies) = image.policy()

  envoy.set("MAGICK_CONFIGURE_PATH", "priv")
  let assert Ok(with_overriden_policies) = image.policy()

  assert default_policies != with_overriden_policies
}
