# alakazam

[![Package Version](https://img.shields.io/hexpm/v/alakazam)](https://hex.pm/packages/alakazam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/alakazam/)

A fluent, type-safe image processing library for Gleam, powered by ImageMagick.

## How It Works

alakazam is a thin, composable wrapper around the ImageMagick `magick`
command-line tool. Rather than binding to a native C library, it builds a
pipeline of operations in Gleam and compiles them into a single `magick`
command that is executed when the image is written.

```gleam
import alakazam/image

pub fn main() {
  image.from_file("photo.jpg")
  |> image.resize_contain(800, 600)
  |> image.sharpen(0.5)
  |> image.to_file("output.jpg")
  // Executes: magick photo.jpg -resize 800x600 -sharpen 0.5 output.jpg
}
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
appropriate for tight loops that process many small images per second.

**Security.** ImageMagick has a history of security vulnerabilities related
to parsing complex image formats. Processing untrusted user uploads directly
can be risky. See the [Security](#security) section for detailed recommendations.

ImageMagick must also be installed on every host that runs your application.
See the [Prerequisites](#prerequisites) section for installation instructions.

## Security

ImageMagick is a powerful tool that can execute complex operations on images.
When processing untrusted user uploads, security is critical. This library includes a
restrictive security policy to minimize attack surface.

The policy is _not_ enabled by default.

### Security Policy

The repository includes `priv/policy.xml` - a whitelist-based ImageMagick security policy that:

- **Blocks all formats by default** - Only explicitly allowed formats can be processed
- **Allows safe formats**: PNG, JPEG, WebP, GIF, BMP, AVIF, PBM, PGM, PPM
- **Blocks dangerous formats**: PDF, PostScript, MVG, MSL, SVG, XPS, WMF, EMF, and others
- **Sets resource limits**: 256MB memory, 1GB disk, 30-second timeout, 16K max dimensions
- **Disables dangerous features**: External command execution, file path expansion, clipboard access, module loading

### Using the Security Policy

**Option 1: Environment Variable (Recommended for Development)**

```bash
export MAGICK_CONFIGURE_PATH=/path/to/alakazam/priv
```

**Option 2: System-wide Installation**

Copy the policy to your ImageMagick configuration directory:

```bash
# macOS (Homebrew)
cp priv/policy.xml /usr/local/etc/ImageMagick-7/policy.xml

# Ubuntu/Debian
sudo cp priv/policy.xml /etc/ImageMagick-7/policy.xml

# Verify the policy is loaded
magick -list policy
```

**Option 3: Docker/Container**

```dockerfile
COPY priv/policy.xml /etc/ImageMagick-7/policy.xml
```

### Production Security Recommendations

1. **Always use a security policy** in production environments processing user uploads
2. **Run in isolated containers** with limited resources and network access
3. **Validate file types** before processing (check magic bytes, not just extensions)
4. **Set file size limits** before images reach ImageMagick
5. **Monitor resource usage** and set up alerts for unusual patterns
6. **Keep ImageMagick updated** with the latest security patches

### Testing the Policy

To verify the policy is working:

```bash
# This should fail (PDF is blocked)
magick document.pdf output.png
# Error: attempt to perform an operation not allowed by the security policy

# This should succeed (PNG is allowed)
magick image.png output.jpg
```

[Read more about security policys here](https://imagemagick.org/script/security-policy.php#gsc.tab=0)

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
gleam add alakazam
```

## Quick Start

```gleam
// Basic resize and save
image.from_file("photo.jpg")
|> image.resize_contain(800, 600)
|> image.to_file("resized.jpg")
```

## Usage Examples

### Resizing Images

```gleam
// Fit within dimensions (preserves aspect ratio)
image.from_file("large.png")
|> image.resize_contain(300, 200)
|> image.to_file("fitted.png")

// Fill exact dimensions (may stretch)
image.from_file("photo.jpg")
|> image.resize_fill(800, 600)
|> image.to_file("filled.jpg")

// Cover/crop to fill (CSS object-fit: cover behavior)
image.from_file("banner.jpg")
|> image.resize_cover(1920, 1080, image.Center)
|> image.to_file("cover.jpg")

// Reduce colors with dithering for retro/pixel art look
image.from_file("photo.jpg")
|> image.dither()
|> image.colors(8)
|> image.to_file("retro.png")
```

### Creating Thumbnails

Thumbnails are optimized for creating preview images - they automatically strip metadata and use less memory:

```gleam
image.from_file("high_res_photo.jpg")
|> image.thumbnail(150, 150)
|> image.to_file("thumb.jpg")
```

### Controlling Resampling Quality

Choose the right filter for your image type:

```gleam
// For pixel art - preserve sharp edges
image.from_file("pixel_art.png")
|> image.filter(image.Nearest)
|> image.resize_contain(200, 200)
|> image.to_file("scaled.png")

// For photos - high quality (default)
image.from_file("photo.jpg")
|> image.filter(image.Lanczos)
|> image.thumbnail(100, 100)
|> image.to_file("thumb.jpg")
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
image.from_file("input.jpg")
|> image.resize_contain(800, 600)
|> image.sharpen(0.5)
|> image.strip()  // Remove metadata for smaller files
|> image.to_file("optimized.jpg")
```

### Getting Image Information

```gleam
import alakazam/image

pub fn main() {
  case image.identify("photo.jpg") {
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
}
```

### Format Conversion

```gleam
// Convert PNG to JPEG
image.from_file("image.png")
|> image.to_file("image.jpg")

// Get image as bytes in specific format
image.from_file("photo.jpg")
|> image.to_bits(image.Png)
```

### Working with Binary Data

```gleam
// Load image from BitArray (e.g., from database or API)
let image_bits = read_image_from_database()
image.from_bits(image_bits)
|> image.resize_contain(100, 100)
|> image.to_file("resized.png")

// Round-trip: File -> BitArray -> File
image.from_file("photo.jpg")
|> image.to_bits(image.Png)
|> image.from_bits
|> image.to_file("converted.png")
```

### Color Reduction

Reduce the color palette for stylistic effects or smaller file sizes. Both operations work well with `dither()` to smooth gradients.

**`colors(n)`** - Reduces to **n total colors** using intelligent quantization. ImageMagick analyzes the image and picks the best colors to represent it.

```gleam
// 8-color image with dithering for smooth gradients
image.from_file("photo.jpg")
|> image.dither()
|> image.colors(8)
|> image.to_file("8color.png")
```

**`posterize(n)`** - Reduces to **n levels per color channel** (R, G, B). Creates `n³` total colors with uniform steps, producing visible color banding (posterization effect).

```gleam
// 4 levels per channel = 4³ = 64 total colors (retro poster look)
image.from_file("photo.jpg")
|> image.dither()
|> image.posterize(4)
|> image.to_file("posterized.png")

// Extreme posterization: 2 levels per channel = only 8 colors total
image.from_file("photo.jpg")
|> image.dither()
|> image.posterize(2)
|> image.to_file("8color-poster.png")
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
- `rotate(image, degrees)` - Rotate image by specified angle
- `quality(image, percent)` - Set JPEG/WebP compression quality (1-100)
- `sepia(image, threshold)` - Apply sepia tone effect
- `gamma(image, value)` - Apply gamma correction
- `brightness_contrast(image, brightness, contrast)` - Adjust brightness and contrast
- `contrast_stretch(image, black_percent, white_percent)` - Enhance contrast by stretching intensity range

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
- `alpha_to_image(image)` - Extract alpha channel as grayscale image

### Metadata

- `strip(image)` - Remove all metadata (EXIF, ICC, comments)
- `identify(path)` - Get detailed image information

### Utilities

- `to_command(image, output_path)` - Returns the ImageMagick command string without executing
- `raw(image, key, value)` - Add custom ImageMagick arguments
- `policy()` - List current ImageMagick security policy configuration

## Supported Formats

- PNG
- JPEG
- WebP
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

Further documentation can be found at [https://hexdocs.pm/alakazam](https://hexdocs.pm/alakazam).

## License

This project is licensed under the MIT License.
