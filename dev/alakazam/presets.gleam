//// Preset effects for the alakazam library.
////
//// This module provides 35 ready-to-use image effect combinations organized
//// into categories. Each preset is a pure function that takes an `Image` and
//// returns a transformed `Image`, making it easy to apply professional-looking
//// effects with a single function call.
////
//// ## Quick Start
////
//// ```gleam
//// import alakazam/image
//// import alakazam/presets
////
//// pub fn main() {
////   image.from_file("photo.jpg")
////   |> presets.vintage_sepia()
////   |> image.to_file("vintage.jpg")
//// }
//// ```
////
//// ## Available Categories
////
//// - **Retro/Vintage** — Classic analog media aesthetics
//// - **Artistic** — Painterly and stylized effects
//// - **Black & White** — Monochrome conversion styles
//// - **Color Grading** — Tone and mood adjustments
//// - **Retro Tech** — Computer and gaming palettes
//// - **Texture/Grain** — Surface texture effects
//// - **Stylized** — Bold artistic interpretations
//// - **Experimental** — Creative and unusual effects
////
//// ## Chaining Presets
////
//// You can chain presets with other alakazam operations:
////
//// ```gleam
//// image.from_file("photo.jpg")
//// |> image.resize_contain(800, 600)
//// |> presets.film_noir()
//// |> image.sharpen(0.5)
//// |> image.to_file("output.jpg")
//// ```

import alakazam/image.{
  type Image, Circles7x7Black, Halftone6x6Orthogonal, Halftone8x8Angled, Nearest,
  Ordered3x3, Percent,
}

// ============================================================================
// RETRO / VINTAGE
// ============================================================================

/// Creates a retro video game aesthetic with 8-color dithered palette.
///
/// This effect reduces the image to just 8 colors using error-diffusion
/// dithering, producing a smooth gradient typical of early computer games
/// and 8-bit graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.retro_game()
/// |> image.to_file("retro.png")
/// ```
///
pub fn retro_game(image: Image) -> Image {
  image
  |> image.dither()
  |> image.colors(8)
}

/// Applies a classic sepia tone effect mimicking aged photographs.
///
/// Combines sepia toning with contrast stretching and subtle brightness
/// adjustments to recreate the look of vintage photography from the early
/// 20th century.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.vintage_sepia()
/// |> image.to_file("vintage.jpg")
/// ```
///
pub fn vintage_sepia(image: Image) -> Image {
  image
  |> image.sepia(80.0)
  |> image.contrast_stretch(2.0, 2.0)
  |> image.brightness_contrast(-10, 10)
  |> image.strip()
}

/// Creates a 1990s web aesthetic with limited color palette.
///
/// Reduces the image to 16 colors with dithering, mimicking the GIF format
/// limitations and dial-up era web graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("banner.jpg")
/// |> presets.web_90s()
/// |> image.to_file("retro_web.gif")
/// ```
///
pub fn web_90s(image: Image) -> Image {
  image
  |> image.dither()
  |> image.colors(16)
}

/// Simulates a halftone newspaper print effect.
///
/// Converts to grayscale and applies angled halftone dots similar to those
/// used in newspaper printing, creating a recognizable vintage print aesthetic.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.newspaper()
/// |> image.to_file("newspaper.jpg")
/// ```
///
pub fn newspaper(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.ordered_dither(Halftone8x8Angled)
  |> image.contrast_stretch(1.0, 1.0)
}

/// Recreates the degraded quality of VHS tape recordings.
///
/// Applies reduced contrast, warm gamma shift, color posterization, and
/// slight blur to mimic analog video tape artifacts.
///
/// ## Example
///
/// ```gleam
/// image.from_file("video_frame.jpg")
/// |> presets.vhs()
/// |> image.to_file("vhs.jpg")
/// ```
///
pub fn vhs(image: Image) -> Image {
  image
  |> image.brightness_contrast(-5, -15)
  |> image.gamma(1.2)
  |> image.posterize(6)
  |> image.blur(0.5)
}

// ============================================================================
// ARTISTIC
// ============================================================================

/// Creates a high-contrast pop art style effect.
///
/// Reduces colors to create flat, bold areas reminiscent of Andy Warhol's
/// screen prints and Roy Lichtenstein's comic-inspired works.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.pop_art()
/// |> image.to_file("pop_art.jpg")
/// ```
///
pub fn pop_art(image: Image) -> Image {
  image
  |> image.posterize(3)
  |> image.brightness_contrast(0, 30)
  |> image.dither()
}

/// Transforms photos into pencil sketch drawings.
///
/// Converts to grayscale, enhances edges with sharpening, and increases
/// contrast to emphasize lines and details like a hand-drawn sketch.
///
/// ## Example
///
/// ```gleam
/// image.from_file("landscape.jpg")
/// |> presets.sketch()
/// |> image.to_file("sketch.jpg")
/// ```
///
pub fn sketch(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.sharpen(2.0)
  |> image.auto_level()
  |> image.brightness_contrast(10, 40)
}

/// Creates a soft, ethereal, dream-like atmosphere.
///
/// Applies blur, brightening, and reduced contrast with gamma adjustment
/// to produce a hazy, romantic quality often used in fantasy and portrait
/// photography.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.dreamy()
/// |> image.to_file("dreamy.jpg")
/// ```
///
pub fn dreamy(image: Image) -> Image {
  image
  |> image.blur(1.5)
  |> image.brightness_contrast(15, -10)
  |> image.gamma(1.1)
}

/// Produces a bright, airy high-key lighting effect.
///
/// Overexposes the image with reduced contrast to create a clean, optimistic,
/// fashion-photography aesthetic with minimal shadows.
///
/// ## Example
///
/// ```gleam
/// image.from_file("product.jpg")
/// |> presets.high_key()
/// |> image.to_file("high_key.jpg")
/// ```
///
pub fn high_key(image: Image) -> Image {
  image
  |> image.brightness_contrast(20, -20)
  |> image.gamma(1.3)
  |> image.normalize()
}

/// Creates dramatic black and white film noir cinematography.
///
/// High contrast grayscale with crushed blacks and bright highlights,
/// evoking classic detective films and dramatic lighting.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.film_noir()
/// |> image.to_file("noir.jpg")
/// ```
///
pub fn film_noir(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.brightness_contrast(-5, 40)
  |> image.gamma(0.9)
}

// ============================================================================
// FUN / EXPERIMENTAL
// ============================================================================

/// Inverts colors and posterizes for a psychedelic neon effect.
///
/// Creates surreal, otherworldly colors by inverting the image and
/// increasing contrast with limited color levels.
///
/// ## Example
///
/// ```gleam
/// image.from_file("cityscape.jpg")
/// |> presets.inverted_neon()
/// |> image.to_file("neon.jpg")
/// ```
///
pub fn inverted_neon(image: Image) -> Image {
  image
  |> image.negate()
  |> image.posterize(4)
  |> image.brightness_contrast(0, 30)
}

/// Transforms photos into retro pixel art sprites.
///
/// Dramatically downscales with nearest-neighbor filtering, reduces colors,
/// then scales back up to create authentic pixelated game graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("character.jpg")
/// |> presets.pixel_art()
/// |> image.to_file("sprite.png")
/// ```
///
pub fn pixel_art(image: Image) -> Image {
  image
  |> image.filter(Nearest)
  |> image.resize(Percent(25.0))
  |> image.dither()
  |> image.colors(16)
  |> image.filter(Nearest)
  |> image.resize(Percent(400.0))
}

/// Creates a high-contrast futuristic cyberpunk aesthetic.
///
/// Enhances brightness and contrast with gamma adjustment and posterization
/// for a neon-soaked, dystopian future look.
///
/// ## Example
///
/// ```gleam
/// image.from_file("city_night.jpg")
/// |> presets.cyberpunk()
/// |> image.to_file("cyberpunk.jpg")
/// ```
///
pub fn cyberpunk(image: Image) -> Image {
  image
  |> image.brightness_contrast(10, 35)
  |> image.gamma(0.85)
  |> image.posterize(5)
}

/// Simulates thermal imaging camera false-color display.
///
/// Converts to grayscale, posterizes, inverts, and auto-levels to mimic
/// the appearance of infrared thermal imaging.
///
/// ## Example
///
/// ```gleam
/// image.from_file("building.jpg")
/// |> presets.thermal()
/// |> image.to_file("thermal.jpg")
/// ```
///
pub fn thermal(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.posterize(8)
  |> image.negate()
  |> image.auto_level()
}

/// Produces a digital glitch art aesthetic.
///
/// Extreme posterization with circular dithering patterns creates
/// corrupted-data artifacts and digital distortion effects.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.glitch()
/// |> image.to_file("glitched.jpg")
/// ```
///
pub fn glitch(image: Image) -> Image {
  image
  |> image.posterize(2)
  |> image.ordered_dither(Circles7x7Black)
  |> image.brightness_contrast(0, 20)
}

// ============================================================================
// BLACK & WHITE VARIATIONS
// ============================================================================

/// Clean, straightforward grayscale conversion.
///
/// Simple desaturation that preserves the full tonal range, suitable for
/// professional black and white photography.
///
/// ## Example
///
/// ```gleam
/// image.from_file("landscape.jpg")
/// |> presets.black_and_white()
/// |> image.to_file("bw.jpg")
/// ```
///
pub fn black_and_white(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
}

/// Dramatic high-contrast black and white.
///
/// Pushes blacks and whites to extremes with auto-leveling for maximum
/// visual impact and dramatic mood.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.high_contrast_bw()
/// |> image.to_file("high_contrast.jpg")
/// ```
///
pub fn high_contrast_bw(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.brightness_contrast(0, 40)
  |> image.auto_level()
}

/// Gentle, soft grayscale conversion with muted contrast.
///
/// Produces a softer, more subtle black and white look with raised gamma
/// and reduced contrast for a delicate feel.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.soft_grayscale()
/// |> image.to_file("soft_bw.jpg")
/// ```
///
pub fn soft_grayscale(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.gamma(1.2)
  |> image.brightness_contrast(5, -10)
}

/// Pure black and white (1-bit) with dithering.
///
/// Converts to true monochrome with only pure black and pure white pixels,
/// using dithering to approximate gray tones. Perfect for bitmap outputs.
///
/// ## Example
///
/// ```gleam
/// image.from_file("logo.jpg")
/// |> presets.monochrome_dithered()
/// |> image.to_file("logo.pbm")
/// ```
///
pub fn monochrome_dithered(image: Image) -> Image {
  image
  |> image.monochrome()
}

// ============================================================================
// COLOR GRADING
// ============================================================================

/// Adds warm, golden tones for a cozy atmosphere.
///
/// Increases brightness and gamma to create a sun-soaked, inviting mood
/// often used in food and lifestyle photography.
///
/// ## Example
///
/// ```gleam
/// image.from_file("sunset.jpg")
/// |> presets.warm_glow()
/// |> image.to_file("warm.jpg")
/// ```
///
pub fn warm_glow(image: Image) -> Image {
  image
  |> image.gamma(1.1)
  |> image.brightness_contrast(10, 5)
}

/// Applies cool, blue-shifted tones for a somber mood.
///
/// Darkens and increases contrast with reduced gamma to create a cold,
/// detached aesthetic common in thriller and sci-fi genres.
///
/// ## Example
///
/// ```gleam
/// image.from_file("winter.jpg")
/// |> presets.cool_tone()
/// |> image.to_file("cool.jpg")
/// ```
///
pub fn cool_tone(image: Image) -> Image {
  image
  |> image.gamma(0.95)
  |> image.brightness_contrast(-5, 10)
}

/// Creates a washed-out, low-saturation faded look.
///
/// Reduces contrast and increases brightness for a vintage film or
/// Polaroid-style effect with bleached colors.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.faded()
/// |> image.to_file("faded.jpg")
/// ```
///
pub fn faded(image: Image) -> Image {
  image
  |> image.brightness_contrast(15, -25)
  |> image.gamma(1.15)
}

/// Enhances colors and contrast for a vibrant, punchy look.
///
/// Normalizes the image, boosts contrast, and sharpens for maximum visual
/// impact and saturated colors.
///
/// ## Example
///
/// ```gleam
/// image.from_file("landscape.jpg")
/// |> presets.vibrant()
/// |> image.to_file("vibrant.jpg")
/// ```
///
pub fn vibrant(image: Image) -> Image {
  image
  |> image.normalize()
  |> image.brightness_contrast(5, 25)
  |> image.sharpen(0.4)
}

/// Mutes colors for a subtle, desaturated aesthetic.
///
/// Reduces contrast and slightly adjusts gamma for a subdued, sophisticated
/// look popular in minimalist and modern design.
///
/// ## Example
///
/// ```gleam
/// image.from_file("product.jpg")
/// |> presets.desaturated()
/// |> image.to_file("muted.jpg")
/// ```
///
pub fn desaturated(image: Image) -> Image {
  image
  |> image.brightness_contrast(0, -20)
  |> image.gamma(1.05)
}

// ============================================================================
// RETRO TECH
// ============================================================================

/// Recreates the 4-shade green Game Boy display.
///
/// Converts to grayscale with 2-bit color depth (4 shades) and dithering
/// to mimic the iconic handheld gaming system's LCD screen.
///
/// ## Example
///
/// ```gleam
/// image.from_file("game_scene.jpg")
/// |> presets.gameboy()
/// |> image.to_file("gameboy.png")
/// ```
///
pub fn gameboy(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.posterize(2)
  |> image.dither()
}

/// Applies the 4-color CGA (Color Graphics Adapter) palette.
///
/// Reduces to 4 colors with extreme posterization and dithering to recreate
/// early 1980s PC graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("scene.jpg")
/// |> presets.cga()
/// |> image.to_file("cga.png")
/// ```
///
pub fn cga(image: Image) -> Image {
  image
  |> image.dither()
  |> image.colors(4)
  |> image.posterize(2)
  |> image.brightness_contrast(0, 30)
}

/// Creates a blocky teletext/videotex aesthetic.
///
/// Dramatically downscales with reduced colors, then scales back up to
/// create chunky, low-resolution text terminal graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("image.jpg")
/// |> presets.teletext()
/// |> image.to_file("teletext.png")
/// ```
///
pub fn teletext(image: Image) -> Image {
  image
  |> image.filter(Nearest)
  |> image.resize(Percent(20.0))
  |> image.colors(8)
  |> image.filter(Nearest)
  |> image.resize(Percent(500.0))
}

/// Mimics the Commodore 64 16-color palette aesthetic.
///
/// Reduces to 16 colors with moderate posterization and color enhancement
/// to evoke the classic home computer's graphics.
///
/// ## Example
///
/// ```gleam
/// image.from_file("retro_scene.jpg")
/// |> presets.commodore64()
/// |> image.to_file("c64.png")
/// ```
///
pub fn commodore64(image: Image) -> Image {
  image
  |> image.dither()
  |> image.colors(16)
  |> image.posterize(4)
  |> image.brightness_contrast(5, 15)
}

// ============================================================================
// TEXTURE / GRAIN
// ============================================================================

/// Adds subtle film grain texture.
///
/// Applies ordered dithering with slight contrast boost to simulate
/// analog film grain without significantly altering the image.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.grainy()
/// |> image.to_file("grainy.jpg")
/// ```
///
pub fn grainy(image: Image) -> Image {
  image
  |> image.ordered_dither(Ordered3x3)
  |> image.brightness_contrast(0, 5)
}

/// Creates ultra-smooth, denoised appearance.
///
/// Applies blur followed by normalization and light sharpening to reduce
/// noise while maintaining edge definition.
///
/// ## Example
///
/// ```gleam
/// image.from_file("noisy_photo.jpg")
/// |> presets.smooth()
/// |> image.to_file("smooth.jpg")
/// ```
///
pub fn smooth(image: Image) -> Image {
  image
  |> image.blur(0.5)
  |> image.normalize()
  |> image.sharpen(0.2)
}

/// Applies color halftone printing effect.
///
/// Uses orthogonal halftone dithering to simulate CMYK printing dot patterns
/// visible in magazines and color printing.
///
/// ## Example
///
/// ```gleam
/// image.from_file("photo.jpg")
/// |> presets.halftone_color()
/// |> image.to_file("halftone.jpg")
/// ```
///
pub fn halftone_color(image: Image) -> Image {
  image
  |> image.ordered_dither(Halftone6x6Orthogonal)
  |> image.brightness_contrast(0, 10)
}

// ============================================================================
// STYLIZED
// ============================================================================

/// Creates bold comic book / graphic novel style.
///
/// Posterizes colors and dramatically sharpens with high contrast for
/// a hand-inked, cel-shaded illustration look.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.comic_book()
/// |> image.to_file("comic.jpg")
/// ```
///
pub fn comic_book(image: Image) -> Image {
  image
  |> image.posterize(5)
  |> image.sharpen(1.0)
  |> image.brightness_contrast(0, 35)
  |> image.auto_level()
}

/// Simulates soft watercolor painting.
///
/// Applies blur with posterization and reduced contrast to create a fluid,
/// painted-on-paper aesthetic with bleeding colors.
///
/// ## Example
///
/// ```gleam
/// image.from_file("landscape.jpg")
/// |> presets.watercolor()
/// |> image.to_file("watercolor.jpg")
/// ```
///
pub fn watercolor(image: Image) -> Image {
  image
  |> image.blur(2.0)
  |> image.posterize(8)
  |> image.brightness_contrast(10, -15)
}

/// Creates textured oil painting effect.
///
/// Combines posterization with moderate blur and contrast boost to simulate
/// thick brush strokes and paint texture.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.oil_painting()
/// |> image.to_file("oil.jpg")
/// ```
///
pub fn oil_painting(image: Image) -> Image {
  image
  |> image.posterize(6)
  |> image.blur(1.0)
  |> image.brightness_contrast(5, 15)
}

/// Produces charcoal sketch drawing effect.
///
/// Converts to grayscale with extreme sharpening and contrast to emphasize
/// edges and create a hand-drawn charcoal aesthetic.
///
/// ## Example
///
/// ```gleam
/// image.from_file("portrait.jpg")
/// |> presets.charcoal()
/// |> image.to_file("charcoal.jpg")
/// ```
///
pub fn charcoal(image: Image) -> Image {
  image
  |> image.colorspace(image.Gray)
  |> image.sharpen(3.0)
  |> image.brightness_contrast(-10, 50)
}
