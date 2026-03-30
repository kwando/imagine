//// A Gleam library for image manipulation powered by ImageMagick.
////
//// Provides a composable API for resizing, cropping, filtering, and
//// converting images through ImageMagick command-line tools.
////
//// ## Basic Usage
////
//// ```gleam
//// import imagine
////
//// fn main() {
////   imagine.from_file("input.jpg")
////   |> imagine.resize_contain(800, 600)
////   |> imagine.to_file("output.jpg")
//// }
//// ```
////
//// This generates the following commands and executes it
////
//// ```sh
//// magick input.jpg -resize 800x600 output.jpg
//// ```
////
//// Operations are chained using the pipe operator (`|>`), building
//// a pipeline of transformations that are executed when the image
//// is written to a file or converted to a BitArray.
////
//// Read more about the available operations in
//// [ImageMagick's documentation](https://imagemagick.org/script/command-line-processing.php).

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
  OrderedDither(String)
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

pub type Resize {
  Fit(Int, Int)
  Fill(Int, Int)
  Exact(Int, Int)
  Width(Int, FitMode)
  Height(Int, FitMode)
  Percent(Float)
  ResizeArea(Int)
}

pub type FitMode {
  Any
  OnlyIfLarger
  OnlyIfSmaller
}

pub type Gravity {
  NorthWest
  North
  NorthEast
  West
  Center
  East
  SouthWest
  South
  SouthEast
}

pub type DitherPattern {
  Threshold
  Checks
  Ordered2x2
  Ordered3x3
  Ordered4x4
  Ordered8x8
  Halftone4x4Angled
  Halftone6x6Angled
  Halftone8x8Angled
  Halftone4x4Orthogonal
  Halftone6x6Orthogonal
  Halftone8x8Orthogonal
  Halftone16x16Orthogonal
  Circles5x5Black
  Circles6x6Black
  Circles7x7Black
  Circles5x5White
  Circles6x6White
  Circles7x7White
}

pub type Colorspace {
  Srgb
  Gray
  Rgb
  Cmyk
  YCbCr
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

pub type Error {
  CannotParseFormat(String)
  CannotParseWidth
  CannotParseHeight
  CannotParseDepth
  CannotParseFileSize
  CannotIdentify(String)
  CommandFailed(exit_code: Int, stderr: String)
  CannotWriteTempFile
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

/// Sets the colorspace of the image (e.g., "sRGB", "Gray", "CMYK").
/// Uses ImageMagick `-colorspace` option.
///
pub fn colorspace(image: Image, kind: String) -> Image {
  prepend_operation(image, Colorspace(kind))
}

/// Converts the image to monochrome (black and white).
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

/// Crops the image to fit within the specified dimensions while preserving
/// aspect ratio, trimming excess from the larger dimension.
/// Respects the gravity setting for crop position.
/// Uses ImageMagick `-crop widthxheight` option.
///
pub fn contain(image: Image, width: Int, height: Int) -> Image {
  prepend_operation(image, Crop(Contain(width, height)))
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

pub type ImageInfo {
  ImageInfo(
    format: Format,
    width: Int,
    height: Int,
    colorspace: Colorspace,
    depth: Int,
    has_alpha: Bool,
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
    _ -> Unknown(input)
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

pub type Format {
  Png
  Bmp
  Jpeg
  Pbm
  Pgm
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
    Monochrome -> ["-monochrome"]
    OrderedDither(kind) -> ["-ordered-dither", kind]
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
    FixedHeight(h) -> int.to_string(h)
    Scale(scale) -> float.to_string(scale) <> "%"
    Area(area) -> int.to_string(area) <> "@"
    Contain(w, h) -> int.to_string(w) <> "x" <> int.to_string(h)
  }
}
