import gleam/bit_array
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout

type Input {
  FileInput(path: String)
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
}

pub opaque type Image {
  Image(source: Input, operations: List(ImageOperation))
}

pub fn from_file(path: String) {
  Image(source: FileInput(path), operations: [])
}

pub fn resize(image, kind: Resize) {
  prepend_operation(image, Resize(kind))
}

pub fn resize_contain(image, width, height) {
  resize(image, Fit(width, height))
}

pub fn resize_fill(image, width, height) {
  resize(image, Exact(width, height))
}

pub fn resize_cover(image, width, height, gravity_val: Gravity) {
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
pub fn thumbnail(image, width: Int, height: Int) {
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
pub fn filter(image, filter: Filter) {
  prepend_operation(image, SetFilter(filter))
}

pub fn extent(image, width, height) {
  prepend_operation(
    image,
    Custom("-extent", int.to_string(width) <> "x" <> int.to_string(height)),
  )
}

pub fn colorspace(image, kind: String) {
  prepend_operation(image, Colorspace(kind))
}

pub fn monochrome(image) {
  prepend_operation(image, Monochrome)
}

pub fn negate(image) {
  prepend_operation(image, Negate)
}

pub fn blur(image, radius: Float) {
  prepend_operation(image, Blur(radius))
}

pub fn auto_orient(image) {
  prepend_operation(image, Custom("-auto-orient", ""))
}

pub fn crop_area(image, pixels: Int) {
  prepend_operation(image, Crop(Area(pixels)))
}

pub fn crop_width(image, pixels: Int) {
  prepend_operation(image, Crop(FixedWidth(pixels)))
}

pub fn contain(image, width: Int, height: Int) {
  prepend_operation(image, Crop(Contain(width, height)))
}

pub fn flip(image) {
  prepend_operation(image, Custom("-flip", ""))
}

pub fn flop(image) {
  prepend_operation(image, Flop)
}

pub fn sharpen(image, radius: Float) {
  prepend_operation(image, Sharpen(radius))
}

pub fn strip(image) {
  prepend_operation(image, Strip)
}

pub fn gravity(image, gravity: Gravity) {
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

fn prepend_operation(image, operation) {
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

fn string_to_format(input) {
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

fn string_to_colorspace(input) {
  case input {
    "sRGB" -> Srgb
    "RGB" -> Rgb
    "Gray" -> Gray
    _ -> Unknown(input)
  }
}

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

pub fn auto_level(image: Image) {
  prepend_operation(image, Custom("-auto-level", ""))
}

pub fn raw(image, key, value) {
  prepend_operation(image, Custom(key, value:))
}

pub fn background(image: Image, color: String) {
  raw(image, "-background", color)
}

pub fn alpha_to_image(image: Image) {
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

// returns the image as a BitArray in the specified format
pub fn to_bits(image: Image, format: Format) {
  apply(image.source, list.reverse(image.operations), StdoutOutput(format:))
  |> result.map(bit_array.from_string)
}

pub fn debug(image) {
  let args = to_args(image, FileOutput("debug.png"))
  io.println("magick " <> string.join(args, " "))
  image
}

// write the image to an file. Make sure to include the format as an extension if you want a change
pub fn to_file(image: Image, path: String) -> Result(String, Error) {
  apply(image.source, list.reverse(image.operations), FileOutput(path))
}

fn to_args(image: Image, output: Output) {
  list.flatten([
    [image.source.path],
    image.operations
      |> list.reverse
      |> list.map(operation_to_args)
      |> list.flatten,
    [output_to_arg(output)],
  ])
}

fn output_to_arg(output: Output) {
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

fn apply(input: Input, commands: List(ImageOperation), output: Output) {
  let args =
    list.flatten([
      [input.path],
      list.map(commands, operation_to_args)
        |> list.flatten,
      [output_to_arg(output)],
    ])

  case shellout.command(run: "magick", with: args, in: ".", opt: []) {
    Ok(data) -> Ok(data)
    Error(#(exit_code, stderr)) -> Error(CommandFailed(exit_code:, stderr:))
  }
}

fn operation_to_args(operation: ImageOperation) {
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

fn geom_to_arg(geometry: CropGeometry) {
  case geometry {
    FixedWidth(w) -> int.to_string(w) <> "x0+0+0"
    FixedHeight(h) -> int.to_string(h)
    Scale(scale) -> float.to_string(scale) <> "%"
    Area(area) -> int.to_string(area) <> "@"
    Contain(w, h) -> int.to_string(w) <> "x" <> int.to_string(h)
  }
}
