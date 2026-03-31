import alakazam/image
import alakazam/presets
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  // For now, use a default image path
  // To use custom image: change this path or pass via environment variable
  let input_path = "IMG_3864.jpeg"

  io.println("🎨 Using default image: " <> input_path)
  io.println(
    "💡 To use a different image, edit dev/alakazam/generate_presets.gleam",
  )
  io.println("")

  generate_all_presets(input_path)
}

fn generate_all_presets(input_path: String) {
  io.println("🎨 Generating all presets from: " <> input_path)
  io.println("")

  // Create output directory
  let output_dir = "dev/output"
  let _ = simplifile.create_directory(output_dir)

  // Define all presets with their names
  let preset_list = [
    // Retro/Vintage
    #("01_retro_game", presets.retro_game),
    #("02_vintage_sepia", presets.vintage_sepia),
    #("03_web_90s", presets.web_90s),
    #("04_newspaper", presets.newspaper),
    #("05_vhs", presets.vhs),
    // Artistic
    #("06_pop_art", presets.pop_art),
    #("07_sketch", presets.sketch),
    #("08_dreamy", presets.dreamy),
    #("09_high_key", presets.high_key),
    #("10_film_noir", presets.film_noir),
    // Fun/Experimental
    #("11_inverted_neon", presets.inverted_neon),
    #("12_pixel_art", presets.pixel_art),
    #("13_cyberpunk", presets.cyberpunk),
    #("14_thermal", presets.thermal),
    #("15_glitch", presets.glitch),
    // Black & White
    #("16_black_and_white", presets.black_and_white),
    #("17_high_contrast_bw", presets.high_contrast_bw),
    #("18_soft_grayscale", presets.soft_grayscale),
    #("19_monochrome_dithered", presets.monochrome_dithered),
    // Color Grading
    #("20_warm_glow", presets.warm_glow),
    #("21_cool_tone", presets.cool_tone),
    #("22_faded", presets.faded),
    #("23_vibrant", presets.vibrant),
    #("24_desaturated", presets.desaturated),
    // Retro Tech
    #("25_gameboy", presets.gameboy),
    #("26_cga", presets.cga),
    #("27_teletext", presets.teletext),
    #("28_commodore64", presets.commodore64),
    // Texture/Grain
    #("29_grainy", presets.grainy),
    #("30_smooth", presets.smooth),
    #("31_halftone_color", presets.halftone_color),
    // Stylized
    #("32_comic_book", presets.comic_book),
    #("33_watercolor", presets.watercolor),
    #("34_oil_painting", presets.oil_painting),
    #("35_charcoal", presets.charcoal),
  ]

  // Generate each preset
  let results =
    list.map(preset_list, fn(preset_info) {
      let #(name, preset_fn) = preset_info
      let output_path = output_dir <> "/" <> name <> ".png"

      io.print("  Generating " <> name <> "... ")

      let result =
        image.from_file(input_path)
        |> image.resize_contain(640, 480)
        |> preset_fn()
        |> image.to_file(output_path)

      case result {
        Ok(_) -> {
          io.println("✓")
          Ok(name)
        }
        Error(err) -> {
          io.println("✗ " <> error_to_string(err))
          Error(name)
        }
      }
    })

  // Summary
  io.println("")
  let success_count =
    list.count(results, fn(r) {
      case r {
        Ok(_) -> True
        Error(_) -> False
      }
    })

  io.println(
    "✨ Complete! Generated "
    <> int.to_string(success_count)
    <> "/"
    <> int.to_string(list.length(preset_list))
    <> " presets",
  )
  io.println("📁 Output directory: " <> output_dir)

  // Generate HTML gallery
  case generate_gallery(output_dir, preset_list) {
    Ok(_) -> {
      io.println("🖼️  HTML gallery: " <> output_dir <> "/gallery.html")
    }
    Error(_) -> {
      io.println("⚠️  Could not generate HTML gallery")
    }
  }
}

fn generate_gallery(
  output_dir: String,
  presets: List(#(String, fn(image.Image) -> image.Image)),
) -> Result(Nil, Nil) {
  let html = build_gallery_html(presets)
  let gallery_path = output_dir <> "/gallery.html"

  simplifile.write(gallery_path, html)
  |> result.replace(Nil)
  |> result.replace_error(Nil)
}

fn build_gallery_html(
  presets: List(#(String, fn(image.Image) -> image.Image)),
) -> String {
  let header =
    "<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Alakazam Presets Gallery</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: #0a0a0a;
      color: #f0f0f0;
      padding: 2rem;
    }
    h1 {
      text-align: center;
      margin-bottom: 3rem;
      font-size: 2.5rem;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .gallery {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 2rem;
      max-width: 1400px;
      margin: 0 auto;
    }
    .preset {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 1rem;
      transition: transform 0.2s, box-shadow 0.2s;
      border: 1px solid #2a2a2a;
    }
    .preset:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 24px rgba(0, 0, 0, 0.5);
      border-color: #667eea;
    }
    .preset img {
      width: 100%;
      height: 240px;
      object-fit: cover;
      border-radius: 8px;
      margin-bottom: 1rem;
      background: #0a0a0a;
    }
    .preset h3 {
      font-size: 1rem;
      color: #667eea;
      margin-bottom: 0.5rem;
      text-transform: capitalize;
    }
    .preset-number {
      font-size: 0.75rem;
      color: #888;
      font-weight: normal;
    }
    .category {
      font-size: 0.75rem;
      color: #aaa;
      padding: 0.25rem 0.75rem;
      background: #2a2a2a;
      border-radius: 12px;
      display: inline-block;
      margin-top: 0.5rem;
    }
  </style>
</head>
<body>
  <h1>✨ Alakazam Presets Gallery</h1>
  <div class=\"gallery\">
"

  let footer =
    "  </div>
</body>
</html>"

  let items =
    list.map(presets, fn(preset) {
      let #(name, _) = preset
      let display_name =
        name
        |> string.split("_")
        |> list.drop(1)
        |> string.join(" ")

      let number = string.slice(name, 0, 2)

      let category = case string.slice(name, 0, 2) {
        "01" | "02" | "03" | "04" | "05" -> "Retro/Vintage"
        "06" | "07" | "08" | "09" | "10" -> "Artistic"
        "11" | "12" | "13" | "14" | "15" -> "Experimental"
        "16" | "17" | "18" | "19" -> "Black & White"
        "20" | "21" | "22" | "23" | "24" -> "Color Grading"
        "25" | "26" | "27" | "28" -> "Retro Tech"
        "29" | "30" | "31" -> "Texture/Grain"
        "32" | "33" | "34" | "35" -> "Stylized"
        _ -> "Other"
      }

      "    <div class=\"preset\">
      <img src=\"" <> name <> ".png\" alt=\"" <> display_name <> "\">
      <h3><span class=\"preset-number\">#" <> number <> "</span> " <> display_name <> "</h3>
      <span class=\"category\">" <> category <> "</span>
    </div>
"
    })

  header <> string.join(items, "") <> footer
}

fn error_to_string(err: image.Error) -> String {
  case err {
    image.CommandFailed(code, stderr) ->
      "Command failed (exit " <> int.to_string(code) <> "): " <> stderr
    image.CannotIdentify(msg) -> "Cannot identify: " <> msg
    image.CannotParseFormat(fmt) -> "Cannot parse format: " <> fmt
    image.CannotParseWidth -> "Cannot parse width"
    image.CannotParseHeight -> "Cannot parse height"
    image.CannotParseDepth -> "Cannot parse depth"
    image.CannotParseFileSize -> "Cannot parse file size"
    image.CannotWriteTempFile -> "Cannot write temp file"
    image.CannotCreateTempFile -> "Cannot create temp file"
  }
}
