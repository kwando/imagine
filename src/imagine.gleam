//// A Gleam library for image manipulation powered by ImageMagick.
////
//// Provides a composable, type-safe API for resizing, cropping, filtering, and
//// converting images through ImageMagick command-line tools. Build image
//// processing pipelines using Gleam's pipe operator (`|>`) and execute them
//// with a single shell command.
////
//// ## Quick Start
////
//// ```gleam
//// import imagine
////
//// pub fn main() {
////   // Basic resize
////   imagine.from_file("input.jpg")
////   |> imagine.resize_contain(800, 600)
////   |> imagine.to_file("output.jpg")
//// }
//// ```
////
//// This generates and executes:
////
//// ```sh
//// magick input.jpg -resize 800x600 output.jpg
//// ```
////
//// ## Pipeline Operations
////
//// Chain multiple transformations that are lazily evaluated when written:
////
//// ```gleam
//// imagine.from_file("photo.jpg")
//// |> imagine.resize_cover(1920, 1080, imagine.Center)
//// |> imagine.sharpen(0.5)
//// |> imagine.strip()  // Remove metadata
//// |> imagine.to_file("hero-banner.jpg")
//// ```
////
//// ## Color Reduction
////
//// Create stylistic effects by reducing the color palette:
////
//// ```gleam
//// // Retro 8-color look with smooth dithering
//// imagine.from_file("photo.jpg")
//// |> imagine.dither()
//// |> imagine.colors(8)
//// |> imagine.to_file("retro.png")
////
//// // Visible color banding (poster effect)
//// imagine.from_file("photo.jpg")
//// |> imagine.dither()
//// |> imagine.posterize(4)  // 4 levels per channel = 64 colors
//// |> imagine.to_file("posterized.png")
//// ```
////
//// ## Debugging
////
//// Preview the generated ImageMagick command without executing:
////
//// ```gleam
//// let command =
////   imagine.from_file("input.png")
////   |> imagine.resize_contain(100, 100)
////   |> imagine.to_command("output.png")
////
//// // command == "magick input.png -resize 100x100 output.png"
//// ```
////
//// ## Prerequisites
////
//// ImageMagick must be installed and the `magick` command available in PATH:
////
//// ```bash
//// # macOS
//// brew install imagemagick
////
//// # Ubuntu/Debian
//// apt-get install imagemagick
//// ```
////
//// See [ImageMagick's documentation](https://imagemagick.org/script/command-line-processing.php)
//// for details on available options and advanced usage.

import gleam/bit_array
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import shellout
import simplifile
import temporary

type Input {
  FileInput(path: String)
  BitArrayInput(bits: BitArray)
}

type Output {
  FileOutput(path: String)
  StdoutOutput(format: Format)
}

type ImageOperation {
  Resize(Resize)
  Thumbnail(Int, Int)
  SetFilter(Filter)
  Colorspace(String)
  ContrastStretch(String)
  Colors(Int)
  OrderedDither(String)
  Dither
  Posterize(Int)
  Monochrome
  Negate
  Blur(radius: Float)
  Sharpen(radius: Float)
  Flop
  Strip
  Crop(CropGeometry)
  Custom(key: String, value: String)
}

type CropGeometry {
  FixedWidth(Int)
  FixedHeight(Int)
  Contain(Int, Int)
  Scale(Float)
  Area(Int)
}

/// Controls how an image is resized. Each variant maps to a specific
/// ImageMagick geometry flag.
///
pub type Resize {
  /// Fits the image within the given dimensions, preserving aspect ratio.
  /// The result will be equal to or smaller than the specified size.
  /// Maps to `-resize widthxheight`.
  ///
  Fit(Int, Int)

  /// Resizes the image to fill the given dimensions, preserving aspect ratio.
  /// The result will be equal to or larger than the specified size, so some
  /// pixels may extend beyond the canvas (use with `extent` to crop the
  /// overflow). Maps to `-resize widthxheight^`.
  ///
  Fill(Int, Int)

  /// Resizes to exactly the given dimensions, ignoring aspect ratio.
  /// The image may be distorted. Maps to `-resize widthxheight!`.
  ///
  Exact(Int, Int)

  /// Resizes to the given width, adjusting height to preserve aspect ratio.
  /// The `FitMode` controls whether the resize is applied conditionally.
  /// Maps to `-resize width`, `-resize width>`, or `-resize width<`.
  ///
  Width(Int, FitMode)

  /// Resizes to the given height, adjusting width to preserve aspect ratio.
  /// The `FitMode` controls whether the resize is applied conditionally.
  /// Maps to `-resize xheight`, `-resize xheight>`, or `-resize xheight<`.
  ///
  Height(Int, FitMode)

  /// Resizes by a percentage of the original dimensions.
  /// Maps to `-resize float%`.
  ///
  Percent(Float)

  /// Resizes so the total pixel area is at most the given number of pixels.
  /// Useful for limiting memory usage regardless of image dimensions.
  /// Maps to `-resize int@`.
  ///
  ResizeArea(Int)
}

/// Controls whether a `Width` or `Height` resize is applied conditionally
/// based on the current image size.
///
pub type FitMode {
  /// Always resize, regardless of whether the image is larger or smaller
  /// than the target. This is the default behaviour.
  ///
  Any

  /// Only resize if the image is larger than the target dimensions.
  /// Smaller images are left untouched. Maps to the `>` geometry flag.
  ///
  OnlyIfLarger

  /// Only resize if the image is smaller than the target dimensions.
  /// Larger images are left untouched. Maps to the `<` geometry flag.
  ///
  OnlyIfSmaller
}

/// Controls the anchor point for crop and extent operations.
///
/// When cropping or padding, gravity determines which part of the image is
/// kept or where the canvas is anchored. For example, `Center` crops from
/// the middle, while `NorthWest` anchors to the top-left corner.
///
/// Set gravity with `gravity/2` before a crop or `extent/3` call, or pass
/// it directly to `resize_cover/4`.
///
pub type Gravity {
  /// Top-left corner.
  NorthWest
  /// Top edge, horizontally centered.
  North
  /// Top-right corner.
  NorthEast
  /// Left edge, vertically centered.
  West
  /// Center of the image (default).
  Center
  /// Right edge, vertically centered.
  East
  /// Bottom-left corner.
  SouthWest
  /// Bottom edge, horizontally centered.
  South
  /// Bottom-right corner.
  SouthEast
}

/// Ordered dithering patterns for use with `ordered_dither/2`.
///
/// Ordered dithering approximates tones by arranging black and white pixels
/// in a fixed spatial pattern rather than random noise. Each family has
/// different visual characteristics:
///
/// - **Threshold / Checks** — simple on/off patterns with no spatial spreading
/// - **Ordered** (`o2x2`–`o8x8`) — smooth Bayer matrix patterns; larger
///   matrices produce finer gradients at the cost of more visible structure
/// - **Halftone Angled** (`h4x4a`–`h8x8a`) — angled halftone dots, similar
///   to traditional print halftoning
/// - **Halftone Orthogonal** (`h4x4o`–`h16x16o`) — axis-aligned halftone dots
/// - **Circles Black/White** (`c5x5b`–`c7x7w`) — circular dot patterns on
///   black or white backgrounds
///
pub type DitherPattern {
  /// Flat threshold: pixels above 50% become white, below become black. No
  /// spatial spreading.
  Threshold
  /// Checkerboard pattern at the 50% threshold boundary.
  Checks
  /// 2×2 Bayer ordered matrix.
  Ordered2x2
  /// 3×3 ordered matrix.
  Ordered3x3
  /// 4×4 Bayer ordered matrix. Good general-purpose choice.
  Ordered4x4
  /// 8×8 Bayer ordered matrix. Finer gradients, more visible grid structure.
  Ordered8x8
  /// 4×4 angled halftone dots.
  Halftone4x4Angled
  /// 6×6 angled halftone dots.
  Halftone6x6Angled
  /// 8×8 angled halftone dots. Closest to traditional print halftoning.
  Halftone8x8Angled
  /// 4×4 orthogonal (axis-aligned) halftone dots.
  Halftone4x4Orthogonal
  /// 6×6 orthogonal halftone dots.
  Halftone6x6Orthogonal
  /// 8×8 orthogonal halftone dots.
  Halftone8x8Orthogonal
  /// 16×16 orthogonal halftone dots. Finest tonal gradients in this family.
  Halftone16x16Orthogonal
  /// 5×5 circular dots on a black background.
  Circles5x5Black
  /// 6×6 circular dots on a black background.
  Circles6x6Black
  /// 7×7 circular dots on a black background.
  Circles7x7Black
  /// 5×5 circular dots on a white background.
  Circles5x5White
  /// 6×6 circular dots on a white background.
  Circles6x6White
  /// 7×7 circular dots on a white background.
  Circles7x7White
}

/// Represents an image colorspace.
///
/// Used both as input to `colorspace/2` and as output in `ImageInfo` returned
/// by `identify/1`. The `Unknown` variant acts as an escape hatch for
/// colorspaces not enumerated here (e.g. `HSL`, `Lab`, `YUV`).
///
pub type Colorspace {
  /// Standard RGB with gamma correction (the most common colorspace for
  /// web and screen images).
  Srgb
  /// Grayscale. See `colorspace/2` for the difference between `Gray` and
  /// `monochrome/1`.
  Gray
  /// Linear RGB, without gamma correction.
  Rgb
  /// Cyan/Magenta/Yellow/Key (Black). Used in print workflows.
  Cmyk
  /// Luma + chroma channels. Used in video and some image compression formats.
  YCbCr
  /// A colorspace not covered by the variants above. The string value is
  /// passed directly to ImageMagick (e.g. `Unknown("HSL")`).
  Unknown(String)
}

/// Resampling filters control the algorithm used when resizing images.
/// Different filters are better suited for different types of images.
///
pub type Filter {
  /// High quality, sharp results with minimal artifacts.
  /// Best for photographs and general-purpose resizing.
  ///
  Lanczos

  /// Good balance of quality and processing speed.
  /// A solid general-purpose choice when speed matters.
  ///
  Bicubic

  /// Fast, pixelated results without interpolation.
  /// Best for pixel art, icons, and images with hard edges.
  ///
  Nearest

  /// Smooth results, particularly good for enlarging images.
  /// Produces softer results than Lanczos when upscaling.
  ///
  Mitchell

  /// Simple linear interpolation, fast but lower quality.
  /// Good for simple downscaling when performance is critical.
  ///
  Triangle

  /// Sharp edges and good detail preservation.
  /// Excellent for text, line art, and images with sharp boundaries.
  ///
  Catrom
}

/// Errors that can be returned by fallible operations in this library.
///
pub type Error {
  /// The image format string returned by ImageMagick could not be mapped to
  /// a known `Format` variant. The raw string is included for debugging.
  CannotParseFormat(String)
  /// The width value in ImageMagick's identify output could not be parsed as
  /// an integer.
  CannotParseWidth
  /// The height value in ImageMagick's identify output could not be parsed as
  /// an integer.
  CannotParseHeight
  /// The bit depth value in ImageMagick's identify output could not be parsed
  /// as an integer.
  CannotParseDepth
  /// The file size value in ImageMagick's identify output could not be parsed
  /// as an integer.
  CannotParseFileSize
  /// ImageMagick's identify output could not be interpreted. The raw output
  /// string is included for debugging.
  CannotIdentify(String)
  /// The ImageMagick command exited with a non-zero status. Includes the exit
  /// code and stderr output.
  CommandFailed(exit_code: Int, stderr: String)
  /// A temporary file was created successfully but writing the image data to
  /// it failed. Used by `from_bits/1`.
  CannotWriteTempFile
  /// The temporary file itself could not be created. Used by `from_bits/1`.
  CannotCreateTempFile
}

pub opaque type Image {
  Image(source: Input, operations: List(ImageOperation))
}

/// Creates an image from a file path.
///
pub fn from_file(path: String) -> Image {
  Image(source: FileInput(path), operations: [])
}

/// Creates an image from a BitArray containing image data. During execution this
/// file will be written to a temporary location and read from there by ImageMagick.
/// The temporary file is written everytime the pipeline is triggered and is automatically
/// cleaned up after execution. This is just a convenience method, prefer to use `from_file`
/// when possible.
///
/// ImageMagick will automatically detect the image format from the binary data
/// (PNG, JPEG, BMP, etc.).
///
/// ## Example
///
/// ```gleam
/// let bits = read_image_from_database()
/// from_bits(bits)
/// |> resize_contain(100, 100)
/// |> to_file("resized.png")
/// ```
///
pub fn from_bits(bits: BitArray) -> Image {
  Image(source: BitArrayInput(bits), operations: [])
}

/// Resizes the image using the specified resize mode.
/// Uses ImageMagick `-resize` option.
///
pub fn resize(image: Image, kind: Resize) -> Image {
  prepend_operation(image, Resize(kind))
}

/// Resizes the image to fit within the specified dimensions while preserving
/// aspect ratio. The image will be equal to or smaller than the given width
/// and height.
/// Uses ImageMagick `-resize widthxheight` option.
///
pub fn resize_contain(image: Image, width: Int, height: Int) -> Image {
  resize(image, Fit(width, height))
}

/// Resizes the image to exactly the specified dimensions, ignoring aspect
/// ratio. The image may be distorted.
/// Uses ImageMagick `-resize widthxheight!` option.
///
pub fn resize_fill(image: Image, width: Int, height: Int) -> Image {
  resize(image, Exact(width, height))
}

/// Resizes the image to fill the specified dimensions, cropping overflow.
/// The image will be resized to cover the entire area, and the cropping
/// position is determined by the gravity parameter.
/// Uses ImageMagick `-resize widthxheight^` and `-extent` options.
///
pub fn resize_cover(
  image: Image,
  width: Int,
  height: Int,
  gravity_val: Gravity,
) -> Image {
  image
  |> resize(Fill(width, height))
  |> gravity(gravity_val)
  |> extent(width, height)
}

/// Creates a thumbnail of the image.
///
/// This is more efficient than using `resize` as it automatically strips
/// metadata (EXIF, ICC profiles, comments) before resizing, resulting in
/// smaller memory usage and faster processing - especially useful for
/// creating preview images from large source files.
///
/// The image will be resized to fit within the specified dimensions while
/// preserving its aspect ratio. The resulting thumbnail dimensions will
/// be equal to or smaller than the specified width and height.
///
/// ## Example
///
/// ```gleam
/// from_file("large_photo.jpg")
/// |> thumbnail(150, 150)
/// |> to_file("preview.jpg")
/// ```
///
pub fn thumbnail(image: Image, width: Int, height: Int) -> Image {
  prepend_operation(image, Thumbnail(width, height))
}

/// Sets the resampling filter for all subsequent resize operations.
///
/// This controls the algorithm used when resizing images. Different filters
/// are better suited for different types of images:
///
/// - **Lanczos** (default) - High quality, sharp results. Best for photographs.
/// - **Bicubic** - Good balance of quality and speed.
/// - **Nearest** - Fast, pixelated results. Best for pixel art and icons.
/// - **Mitchell** - Good for enlarging, produces smoother results than Lanczos.
/// - **Triangle** - Simple linear interpolation. Faster but lower quality.
/// - **Catrom** - Sharp edges, good for text and line art.
///
/// The filter setting applies to all subsequent `resize`, `resize_contain`,
/// `resize_fill`, `resize_cover`, and `thumbnail` operations in the pipeline.
///
/// ## Example
///
/// ```gleam
/// from_file("pixel_art.png")
/// |> filter(Nearest)  // Preserve sharp edges
/// |> resize_contain(100, 100)
/// |> to_file("resized.png")
/// ```
///
pub fn filter(image: Image, filter: Filter) -> Image {
  prepend_operation(image, SetFilter(filter))
}

/// Crops or pads the image to the exact specified dimensions.
/// Uses ImageMagick `-extent widthxheight` option.
///
pub fn extent(image: Image, width: Int, height: Int) -> Image {
  prepend_operation(
    image,
    Custom("-extent", int.to_string(width) <> "x" <> int.to_string(height)),
  )
}

/// Sets the colorspace of the image.
///
/// When converting to grayscale, prefer `Gray` over `monochrome/1`. `Gray`
/// preserves the full 256-level tonal range, producing smooth gradients and
/// intermediate gray values. `monochrome/1` reduces the image to pure black
/// and white only (1-bit), using dithering to approximate tones.
///
/// Uses ImageMagick `-colorspace` option.
///
pub fn colorspace(image: Image, kind: Colorspace) -> Image {
  prepend_operation(image, Colorspace(colorspace_to_string(kind)))
}

/// Enhances the contrast of the image by stretching the range of intensity values.
/// The `levels` parameter specifies how much to stretch, with common values like
/// "2%x2%" stretching 2% of the darkest and lightest pixels.
/// Uses ImageMagick `-contrast-stretch` option.
///
pub fn contrast_stretch(image: Image, levels: String) -> Image {
  prepend_operation(image, ContrastStretch(levels))
}

/// Reduces the number of colors in the image to at most the specified number.
///
/// This uses quantization to select the best colors to represent the image.
/// Combine with `dither/1` for smoother gradients when reducing to few colors.
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> image.dither()
/// |> image.colors(8)
/// |> image.to_file("output.png")
/// ```
///
/// Uses ImageMagick `-colors` option.
///
pub fn colors(image: Image, num_colors: Int) -> Image {
  prepend_operation(image, Colors(num_colors))
}

/// Converts the image to monochrome (pure black and white, 1-bit).
///
/// Unlike `colorspace(image, Gray)`, this produces only pure black and pure
/// white pixels — no intermediate grays. ImageMagick applies dithering to
/// approximate tones using patterns of black and white dots.
///
/// Use this when you need a hard black-and-white result (e.g. PBM output,
/// printed bitmaps). Use `colorspace(image, Gray)` instead when you want to
/// preserve the full 256-level grayscale tonal range.
///
/// Uses ImageMagick `-monochrome` option.
///
pub fn monochrome(image: Image) -> Image {
  prepend_operation(image, Monochrome)
}

/// Negates the colors in the image (color inversion).
/// Uses ImageMagick `-negate` option.
///
pub fn negate(image: Image) -> Image {
  prepend_operation(image, Negate)
}

/// Applies a Gaussian blur to the image.
/// Uses ImageMagick `-blur radius` option.
///
pub fn blur(image: Image, radius: Float) -> Image {
  prepend_operation(image, Blur(radius))
}

/// Automatically adjusts the image orientation based on EXIF data.
/// Uses ImageMagick `-auto-orient` option.
///
pub fn auto_orient(image: Image) -> Image {
  prepend_operation(image, Custom("-auto-orient", ""))
}

/// Crops the image to the specified area in pixels.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop pixels@` option.
///
pub fn crop_area(image: Image, pixels: Int) -> Image {
  prepend_operation(image, Crop(Area(pixels)))
}

/// Crops the image to a fixed width, keeping the full height.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop widthx0` option.
///
pub fn crop_width(image: Image, pixels: Int) -> Image {
  prepend_operation(image, Crop(FixedWidth(pixels)))
}

/// Crops the image to a fixed height, keeping the full width.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop 0xheight` option.
///
pub fn crop_height(image: Image, pixels: Int) -> Image {
  prepend_operation(image, Crop(FixedHeight(pixels)))
}

/// Crops the image to fit within the specified dimensions while preserving
/// aspect ratio, trimming excess from the larger dimension.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop widthxheight` option.
///
pub fn contain(image: Image, width: Int, height: Int) -> Image {
  prepend_operation(image, Crop(Contain(width, height)))
}

/// Scales the image by the specified percentage.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop scale%` option.
///
pub fn scale(image: Image, percent: Float) -> Image {
  prepend_operation(image, Crop(Scale(percent)))
}

/// Flips the image vertically (top becomes bottom).
/// Uses ImageMagick `-flip` option.
///
pub fn flip(image: Image) -> Image {
  prepend_operation(image, Custom("-flip", ""))
}

/// Flops the image horizontally (left becomes right).
/// Uses ImageMagick `-flop` option.
///
pub fn flop(image: Image) -> Image {
  prepend_operation(image, Flop)
}

/// Sharpens the image using an unsharp mask.
/// Uses ImageMagick `-sharpen radius` option.
///
pub fn sharpen(image: Image, radius: Float) -> Image {
  prepend_operation(image, Sharpen(radius))
}

/// Strips all metadata (EXIF, ICC profiles, comments) from the image.
/// Uses ImageMagick `-strip` option.
///
pub fn strip(image: Image) -> Image {
  prepend_operation(image, Strip)
}

/// Sets the gravity (position) for crop and extent operations.
/// Used with `-gravity` option.
///
pub fn gravity(image: Image, gravity: Gravity) -> Image {
  prepend_operation(
    image,
    Custom("-gravity", case gravity {
      NorthWest -> "northwest"
      North -> "north"
      NorthEast -> "northeast"
      West -> "west"
      Center -> "center"
      East -> "east"
      SouthWest -> "southwest"
      South -> "south"
      SouthEast -> "southeast"
    }),
  )
}

fn prepend_operation(image: Image, operation: ImageOperation) -> Image {
  Image(..image, operations: [operation, ..image.operations])
}

/// Metadata about an image, returned by `identify/1`.
///
pub type ImageInfo {
  ImageInfo(
    /// The image format (e.g. `Png`, `Jpeg`).
    format: Format,
    /// Image width in pixels.
    width: Int,
    /// Image height in pixels.
    height: Int,
    /// The colorspace of the image data (e.g. `Srgb`, `Gray`).
    colorspace: Colorspace,
    /// Bit depth per channel (e.g. 8 for standard images, 16 for HDR).
    depth: Int,
    /// Whether the image has an alpha (transparency) channel.
    has_alpha: Bool,
    /// File size in bytes.
    file_size: Int,
  )
}

/// Identifies image properties (format, dimensions, colorspace, etc.).
/// Uses ImageMagick `identify` command.
///
pub fn identify(path: String) -> Result(ImageInfo, Error) {
  let cmd_result =
    shellout.command(
      run: "magick",
      with: [
        "identify",
        "-format",
        "%m %w %h %[colorspace] %[depth] %[opaque] %[size]",
        path,
      ],
      in: ".",
      opt: [],
    )

  case cmd_result {
    Ok(identity_str) -> {
      case string.split(identity_str, " ") {
        [format, width, height, colorspace, depth, is_opaque, size] -> {
          use format <- result.try(
            string_to_format(format)
            |> result.replace_error(CannotParseFormat(format)),
          )
          use width <- result.try(
            int.parse(width)
            |> result.replace_error(CannotParseWidth),
          )
          use height <- result.try(
            int.parse(height) |> result.replace_error(CannotParseHeight),
          )
          use depth <- result.try(
            int.parse(depth) |> result.replace_error(CannotParseDepth),
          )
          use file_size <- result.try(
            int.parse(string.drop_end(size, 1))
            |> result.replace_error(CannotParseFileSize),
          )
          let has_alpha = is_opaque == "False"
          let colorspace = string_to_colorspace(colorspace)
          Ok(ImageInfo(
            format:,
            width:,
            height:,
            colorspace:,
            depth:,
            has_alpha:,
            file_size:,
          ))
        }
        _ -> Error(CannotIdentify(identity_str))
      }
    }
    Error(#(exit_code, stderr)) -> Error(CommandFailed(exit_code:, stderr:))
  }
}

fn string_to_format(input: String) -> Result(Format, Nil) {
  case input {
    "BMP" -> Ok(Bmp)
    "BMP3" -> Ok(Bmp)
    "JPEG" -> Ok(Jpeg)
    "PNG" -> Ok(Png)
    "PBM" -> Ok(Pbm)
    "PGM" -> Ok(Pgm)
    _ -> Error(Nil)
  }
}

fn string_to_colorspace(input: String) -> Colorspace {
  case input {
    "sRGB" -> Srgb
    "RGB" -> Rgb
    "Gray" -> Gray
    "CMYK" -> Cmyk
    "YCbCr" -> YCbCr
    _ -> Unknown(input)
  }
}

fn colorspace_to_string(colorspace: Colorspace) -> String {
  case colorspace {
    Srgb -> "sRGB"
    Rgb -> "RGB"
    Gray -> "Gray"
    Cmyk -> "CMYK"
    YCbCr -> "YCbCr"
    Unknown(s) -> s
  }
}

/// Applies an ordered dithering pattern to the image.
/// Uses ImageMagick `-ordered-dither` option.
///
pub fn ordered_dither(image: Image, kind: DitherPattern) -> Image {
  let pattern = case kind {
    Threshold -> "threshold"
    Checks -> "checks"
    Ordered2x2 -> "o2x2"
    Ordered3x3 -> "o3x3"
    Ordered4x4 -> "o4x4"
    Ordered8x8 -> "o8x8"
    Halftone4x4Angled -> "h4x4a"
    Halftone6x6Angled -> "h6x6a"
    Halftone8x8Angled -> "h8x8a"
    Halftone4x4Orthogonal -> "h4x4o"
    Halftone6x6Orthogonal -> "h6x6o"
    Halftone8x8Orthogonal -> "h8x8o"
    Halftone16x16Orthogonal -> "h16x16o"
    Circles5x5Black -> "c5x5b"
    Circles6x6Black -> "c6x6b"
    Circles7x7Black -> "c7x7b"
    Circles5x5White -> "c5x5w"
    Circles6x6White -> "c6x6w"
    Circles7x7White -> "c7x7w"
  }
  prepend_operation(image, OrderedDither(pattern))
}

/// Enables error-diffusion dithering for subsequent color reduction operations.
///
/// Error-diffusion dithering (Floyd-Steinberg) produces smoother gradients than
/// ordered dithering when reducing colors. It propagates quantization errors to
/// neighboring pixels rather than using a fixed pattern.
///
/// Commonly used with `colors/2` to reduce the palette while preserving
/// smooth transitions:
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> image.dither()
/// |> image.colors(8)
/// |> image.to_file("output.png")
/// ```
///
/// Uses ImageMagick `-dither FloydSteinberg` option.
///
pub fn dither(image: Image) -> Image {
  prepend_operation(image, Dither)
}

/// Reduces the image to a fixed number of color levels.
///
/// The `levels` argument specifies how many levels per channel to use. For
/// example, `posterize(image, 4)` produces at most 4^3 = 64 colors.
///
/// Use `dither/1` before this function to enable error-diffusion dithering
/// for smoother transitions between color levels.
///
/// ## Example
///
/// ```gleam
/// // Retro 4-color look with dithering
/// image.from_file("photo.jpg")
/// |> image.dither()
/// |> image.posterize(2)
/// |> image.to_file("output.png")
/// ```
///
/// Uses ImageMagick `-posterize` option.
///
pub fn posterize(image: Image, levels: Int) -> Image {
  prepend_operation(image, Posterize(levels))
}

/// Automatically adjusts the image's color levels.
/// Uses ImageMagick `-auto-level` option.
///
pub fn auto_level(image: Image) -> Image {
  prepend_operation(image, Custom("-auto-level", ""))
}

/// This is an escape hatch to add options that are unsupported by this library
///
/// ## Example
///
/// ```gleam
/// image.from_file("input.png")
/// |> image.raw("-brightness-contrast", "0x30")  // Increase contrast by 30%
/// |> image.to_file("output.jpg")
/// ```
///
pub fn raw(image: Image, key: String, value: String) -> Image {
  prepend_operation(image, Custom(key, value:))
}

/// Sets the background color for operations like extent that may create
/// empty areas.
/// Uses ImageMagick `-background` option.
///
pub fn background(image: Image, color: String) -> Image {
  raw(image, "-background", color)
}

/// Extracts the alpha channel as a grayscale image.
/// Uses ImageMagick `-alpha extract` option.
///
pub fn alpha_to_image(image: Image) -> Image {
  image
  |> raw("-alpha", "extract")
}

/// Output image format, used with `to_bits/2` and inferred from the file
/// extension by `to_file/2`.
///
pub type Format {
  /// Portable Network Graphics. Lossless, supports transparency.
  Png
  /// Windows Bitmap. Uncompressed, widely compatible.
  Bmp
  /// JPEG. Lossy compression, no transparency. Best for photographs.
  Jpeg
  /// Portable Bitmap. 1-bit black and white, plain-text or binary encoding.
  Pbm
  /// Portable Graymap. 8-bit grayscale, plain-text or binary encoding.
  Pgm
  /// Preserve the original format. When used with `to_bits/2`, ImageMagick
  /// writes to stdout without re-encoding, keeping the original format and
  /// compression intact.
  Keep
}

/// Outputs the image as a BitArray in the specified format.
/// Uses ImageMagick output to stdout.
///
pub fn to_bits(image: Image, format: Format) -> Result(BitArray, Error) {
  execute_commands(
    image.source,
    list.reverse(image.operations),
    StdoutOutput(format:),
  )
  |> result.map(bit_array.from_string)
}

/// Returns the ImageMagick command that would be executed for this image pipeline.
///
/// This is useful for debugging or logging purposes. The returned string includes
/// the "magick" command prefix and can be copy-pasted directly into a terminal.
///
/// ## Example
///
/// ```gleam
/// let command =
///   from_file("input.png")
///   |> resize_contain(100, 100)
///   |> to_command("output.png")
///
/// // command == "magick input.png -resize 100x100 output.png"
/// ```
///
pub fn to_command(image: Image, output_path: String) -> String {
  let args = to_args(image, FileOutput(output_path))
  "magick " <> string.join(args, " ")
}

/// Writes the image to a file.
/// Uses ImageMagick convert command.
///
pub fn to_file(image: Image, path: String) -> Result(String, Error) {
  execute_commands(
    image.source,
    list.reverse(image.operations),
    FileOutput(path),
  )
}

fn to_args(image: Image, output: Output) -> List(String) {
  let input = case image.source {
    FileInput(path:) -> path
    BitArrayInput(_) -> "<bitarray>"
  }

  list.flatten([
    [input],
    image.operations
      |> list.reverse
      |> list.map(operation_to_args)
      |> list.flatten,
    [output_to_arg(output)],
  ])
}

fn output_to_arg(output: Output) -> String {
  case output {
    FileOutput(path:) -> path
    StdoutOutput(Keep) -> "-"
    StdoutOutput(format: Png) -> "png:-"
    StdoutOutput(format: Bmp) -> "bmp:-"
    StdoutOutput(format: Jpeg) -> "jpg:-"
    StdoutOutput(format: Pbm) -> "pbm:-"
    StdoutOutput(format: Pgm) -> "pgm:-"
  }
}

fn execute_commands(
  input: Input,
  commands: List(ImageOperation),
  output: Output,
) -> Result(String, Error) {
  case input {
    FileInput(path:) -> execute_commands_on_file(path, commands, output)
    BitArrayInput(bits:) -> {
      use path <- with_temp_file(bits)
      execute_commands_on_file(path, commands, output)
    }
  }
}

fn execute_commands_on_file(
  input_path: String,
  commands: List(ImageOperation),
  output: Output,
) -> Result(String, Error) {
  let args =
    list.flatten([
      [input_path],
      list.map(commands, operation_to_args)
        |> list.flatten,
      [output_to_arg(output)],
    ])
  case shellout.command(run: "magick", with: args, in: ".", opt: []) {
    Ok(data) -> Ok(data)
    Error(#(exit_code, stderr)) -> Error(CommandFailed(exit_code:, stderr:))
  }
}

fn with_temp_file(
  data: BitArray,
  callback: fn(String) -> Result(a, Error),
) -> Result(a, Error) {
  case
    {
      use path <- temporary.create(temporary.file())
      use _ <- result.try(
        simplifile.write_bits(path, data)
        |> result.replace_error(CannotWriteTempFile),
      )
      callback(path)
    }
  {
    Ok(value) -> value
    Error(_) -> Error(CannotCreateTempFile)
  }
}

fn operation_to_args(operation: ImageOperation) -> List(String) {
  case operation {
    Resize(kind) -> ["-resize", resize_to_string(kind)]
    Thumbnail(width, height) -> [
      "-thumbnail",
      int.to_string(width) <> "x" <> int.to_string(height),
    ]
    SetFilter(filter) -> ["-filter", filter_to_string(filter)]
    Colorspace(kind) -> ["-colorspace", kind]
    ContrastStretch(kind) -> ["-contrast-stretch", kind]
    Colors(n) -> ["-colors", int.to_string(n)]
    Monochrome -> ["-monochrome"]
    OrderedDither(kind) -> ["-ordered-dither", kind]
    Dither -> ["-dither", "FloydSteinberg"]
    Posterize(levels) -> ["-posterize", int.to_string(levels)]
    Negate -> ["-negate"]
    Blur(radius:) -> ["-blur", float.to_string(radius)]
    Sharpen(radius:) -> ["-sharpen", float.to_string(radius)]
    Flop -> ["-flop"]
    Strip -> ["-strip"]
    Crop(geometry) -> ["-crop", geom_to_arg(geometry)]
    Custom(key:, value: "") -> [key]
    Custom(key:, value:) -> [key, value]
  }
}

fn resize_to_string(resize: Resize) -> String {
  case resize {
    Fit(w, h) -> int.to_string(w) <> "x" <> int.to_string(h)
    Fill(w, h) -> int.to_string(w) <> "x" <> int.to_string(h) <> "^"
    Exact(w, h) -> int.to_string(w) <> "x" <> int.to_string(h) <> "!"
    Width(w, mode) -> int.to_string(w) <> fit_mode_to_string(mode)
    Height(h, mode) -> "x" <> int.to_string(h) <> fit_mode_to_string(mode)
    Percent(p) -> float.to_string(p) <> "%"
    ResizeArea(a) -> int.to_string(a) <> "@"
  }
}

fn fit_mode_to_string(mode: FitMode) -> String {
  case mode {
    Any -> ""
    OnlyIfLarger -> ">"
    OnlyIfSmaller -> "<"
  }
}

fn filter_to_string(filter: Filter) -> String {
  case filter {
    Lanczos -> "Lanczos"
    Bicubic -> "Cubic"
    Nearest -> "Point"
    Mitchell -> "Mitchell"
    Triangle -> "Triangle"
    Catrom -> "Catrom"
  }
}

fn geom_to_arg(geometry: CropGeometry) -> String {
  case geometry {
    FixedWidth(w) -> int.to_string(w) <> "x0"
    FixedHeight(h) -> "0x" <> int.to_string(h)
    Scale(scale) -> float.to_string(scale) <> "%"
    Area(area) -> int.to_string(area) <> "@"
    Contain(w, h) -> int.to_string(w) <> "x" <> int.to_string(h)
  }
}
