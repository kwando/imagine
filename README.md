# imagine

[![Package Version](https://img.shields.io/hexpm/v/imagine)](https://hex.pm/packages/imagine)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/imagine/)

A fluent, type-safe image processing library for Gleam, powered by ImageMagick.

## How It Works

imagine is a thin, composable wrapper around the ImageMagick `magick`
command-line tool. Rather than binding to a native C library, it builds a
pipeline of operations in Gleam and compiles them into a single `magick`
command that is executed when the image is written.

```gleam
imagine.from_file("photo.jpg")
|> imagine.resize_contain(800, 600)
|> imagine.sharpen(0.5)
|> imagine.to_file("output.jpg")
// Executes: magick photo.jpg -resize 800x600 -sharpen 0.5 output.jpg
```

You can inspect the generated command at any point using `to_command/2`,
which returns the full command string without executing it — useful for
debugging or logging.

### Why a CLI wrapper?

**No native bindings.** There is no FFI layer, no platform-specific
compilation, and no memory safety concerns at the binding boundary. The
library is pure Gleam; only the `magick` binary is native.

**Battle-tested engine.** ImageMagick has over 30 years of development
behind it. Format quirks, ICC profiles, EXIF handling, and hundreds of
other edge cases are handled by a mature, widely-deployed tool rather than
a new binding.

**Transparent and debuggable.** Because the library produces a plain shell
command, you can inspect exactly what will run with `to_command/2` and
paste it directly into a terminal to reproduce or investigate any result.

**Full feature access.** The `raw/3` escape hatch lets you pass any
ImageMagick option the library does not explicitly wrap, so you are never
blocked by a missing API.

### Tradeoffs

Each pipeline execution spawns an OS process. This is well-suited for
batch processing, image pipelines, and server-side generation, but is not
appropriate for tight loops that process many small images per second. For
those workloads, consider batching operations or pre-generating assets.

ImageMagick must also be installed on every host that runs your application.
See the [Prerequisites](#prerequisites) section for installation instructions.

## Prerequisites

ImageMagick must be installed and the `magick` command must be available in your PATH.

```bash
# macOS
brew install imagemagick

# Ubuntu/Debian
apt-get install imagemagick

# Verify installation
magick -version
```

## Installation

```sh
gleam add imagine
```

## Quick Start

```gleam
import imagine

pub fn main() {
  // Basic resize and save
  imagine.from_file("photo.jpg")
  |> imagine.resize_contain(800, 600)
  |> imagine.to_file("resized.jpg")
}
```

## Usage Examples

### Resizing Images

```gleam
import imagine

pub fn resize_examples() {
  // Fit within dimensions (preserves aspect ratio)
  imagine.from_file("large.png")
  |> imagine.resize_contain(300, 200)
  |> imagine.to_file("fitted.png")

  // Fill exact dimensions (may stretch)
  imagine.from_file("photo.jpg")
  |> imagine.resize_fill(800, 600)
  |> imagine.to_file("filled.jpg")

  // Cover/crop to fill (CSS object-fit: cover behavior)
  imagine.from_file("banner.jpg")
  |> imagine.resize_cover(1920, 1080, imagine.Center)
  |> imagine.to_file("cover.jpg")

  // Reduce colors with dithering for retro/pixel art look
  imagine.from_file("photo.jpg")
  |> imagine.dither()
  |> imagine.colors(8)
  |> imagine.to_file("retro.png")
}
```

### Creating Thumbnails

Thumbnails are optimized for creating preview images - they automatically strip metadata and use less memory:

```gleam
imagine.from_file("high_res_photo.jpg")
|> imagine.thumbnail(150, 150)
|> imagine.to_file("thumb.jpg")
```

### Controlling Resampling Quality

Choose the right filter for your image type:

```gleam
// For pixel art - preserve sharp edges
imagine.from_file("pixel_art.png")
|> imagine.filter(imagine.Nearest)
|> imagine.resize_contain(200, 200)
|> imagine.to_file("scaled.png")

// For photos - high quality (default)
imagine.from_file("photo.jpg")
|> imagine.filter(imagine.Lanczos)
|> imagine.thumbnail(100, 100)
|> imagine.to_file("thumb.jpg")
```

Available filters:

- `Lanczos` - High quality, sharp results (best for photos)
- `Bicubic` - Good balance of quality and speed
- `Nearest` - Fast, pixelated (best for pixel art)
- `Mitchell` - Smooth, good for enlarging
- `Triangle` - Fast, simple interpolation
- `Catrom` - Sharp edges, good for text

### Chaining Operations

Combine multiple transformations in a single pipeline:

```gleam
imagine.from_file("input.jpg")
|> imagine.resize_contain(800, 600)
|> imagine.sharpen(0.5)
|> imagine.strip()  // Remove metadata for smaller files
|> imagine.to_file("optimized.jpg")
```

### Getting Image Information

```gleam
case imagine.identify("photo.jpg") {
  Ok(info) -> {
    io.println("Format: " <> format_to_string(info.format))
    io.println("Dimensions: " <> int.to_string(info.width) <> "x" <> int.to_string(info.height))
    io.println("Colorspace: " <> colorspace_to_string(info.colorspace))
    io.println("Bit depth: " <> int.to_string(info.depth))
    io.println("File size: " <> int.to_string(info.file_size) <> " bytes")
    io.println("Has alpha: " <> bool.to_string(info.has_alpha))
  }
  Error(e) -> io.println("Failed to identify image")
}
```

### Format Conversion

```gleam
// Convert PNG to JPEG
imagine.from_file("image.png")
|> imagine.to_file("image.jpg")

// Get image as bytes in specific format
imagine.from_file("photo.jpg")
|> imagine.to_bits(imagine.Png)
```

### Working with Binary Data

```gleam
// Load image from BitArray (e.g., from database or API)
let image_bits = read_image_from_database()
imagine.from_bits(image_bits)
|> imagine.resize_contain(100, 100)
|> imagine.to_file("resized.png")

// Round-trip: File -> BitArray -> File
imagine.from_file("photo.jpg")
|> imagine.to_bits(imagine.Png)
|> imagine.from_bits
|> imagine.to_file("converted.png")
```

### Color Reduction

Reduce the color palette for stylistic effects or smaller file sizes. Both operations work well with `dither()` to smooth gradients.

**`colors(n)`** - Reduces to **n total colors** using intelligent quantization. ImageMagick analyzes the image and picks the best colors to represent it.

```gleam
// 8-color image with dithering for smooth gradients
imagine.from_file("photo.jpg")
|> imagine.dither()
|> imagine.colors(8)
|> imagine.to_file("8color.png")
```

**`posterize(n)`** - Reduces to **n levels per color channel** (R, G, B). Creates `n³` total colors with uniform steps, producing visible color banding (posterization effect).

```gleam
// 4 levels per channel = 4³ = 64 total colors (retro poster look)
imagine.from_file("photo.jpg")
|> imagine.dither()
|> imagine.posterize(4)
|> imagine.to_file("posterized.png")

// Extreme posterization: 2 levels per channel = only 8 colors total
imagine.from_file("photo.jpg")
|> imagine.dither()
|> imagine.posterize(2)
|> imagine.to_file("8color-poster.png")
```

**When to use:**
- **`colors()`** - When you want a specific small palette optimized for the image (e.g., 8-color GIF)
- **`posterize()`** - When you want visible color banding/retro poster effects with uniform color steps

## Available Operations

### Loading & Saving

- `from_file(path)` - Load image from file
- `from_bits(bits)` - Load image from BitArray (auto-detects format)
- `to_file(image, path)` - Save image to file
- `to_bits(image, format)` - Get image as BitArray

### Resizing

- `resize(image, kind)` - General resize with Resize type
- `resize_contain(image, width, height)` - Fit within bounds (CSS: contain)
- `resize_fill(image, width, height)` - Exact dimensions (CSS: fill)
- `resize_cover(image, width, height, gravity)` - Cover with crop (CSS: cover)
- `thumbnail(image, width, height)` - Optimized for previews

### Quality Control

- `filter(image, filter)` - Set resampling filter for resizes

### Effects

- `blur(image, radius)` - Gaussian blur
- `sharpen(image, radius)` - Sharpen image
- `monochrome(image)` - Convert to black and white
- `negate(image)` - Invert colors
- `dither(image)` - Enable Floyd-Steinberg error-diffusion dithering
- `ordered_dither(image, pattern)` - Apply ordered dithering patterns
- `colors(image, num)` - Reduce colors (use with `dither()` for smooth results)
- `posterize(image, levels)` - Reduce color levels per channel

### Transformations

- `flip(image)` - Vertical mirror
- `flop(image)` - Horizontal mirror
- `gravity(image, gravity)` - Set crop/resize anchor point
- `extent(image, width, height)` - Extend/crop to exact size
- `auto_orient(image)` - Auto-rotate based on EXIF

### Cropping

- `crop(image, x, y, width, height)` - Crop to a specific rectangle at position (x, y) with given dimensions

### Colors & Color Space

- `colorspace(image, kind)` - Convert colorspace (accepts `Colorspace` type)
- `auto_level(image)` - Auto-adjust levels
- `normalize(image)` - Normalize (enhance contrast by stretching intensity range)
- `background(image, color)` - Set background color
- `alpha_to_image(image)` - Extract alpha channel

### Metadata

- `strip(image)` - Remove all metadata (EXIF, ICC, comments)
- `identify(path)` - Get detailed image information

### Utilities

- `to_command(image, output_path)` - Returns the ImageMagick command string without executing
- `raw(image, key, value)` - Add custom ImageMagick arguments

## Supported Formats

- PNG
- JPEG
- BMP
- PBM (Portable Bitmap)
- PGM (Portable GrayMap)

Use `Keep` format to maintain the original format when converting.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam format --check src test  # Check formatting
```

## Documentation

Further documentation can be found at [https://hexdocs.pm/imagine](https://hexdocs.pm/imagine).

## License

This project is licensed under the Apache License 2.0.
