//// Preset effects for the imagine library.
////
//// This module provides 35 ready-to-use image effect combinations organized
//// into categories. Each preset is a pure function that takes an `Image` and
//// returns a transformed `Image`, making it easy to apply professional-looking
//// effects with a single function call.
////
//// ## Quick Start
////
//// ```gleam
//// import imagine
//// import imagine/presets
////
//// pub fn main() {
////   imagine.from_file("photo.jpg")
////   |> presets.vintage_sepia()
////   |> imagine.to_file("vintage.jpg")
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
//// You can chain presets with other imagine operations:
////
//// ```gleam
//// imagine.from_file("photo.jpg")
//// |> imagine.resize_contain(800, 600)
//// |> presets.film_noir()
//// |> imagine.sharpen(0.5)
//// |> imagine.to_file("output.jpg")
//// ```

import imagine.{
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
/// imagine.from_file("photo.jpg")
/// |> presets.retro_game()
/// |> imagine.to_file("retro.png")
/// ```
///
pub fn retro_game(image: Image) -> Image {
  image
  |> imagine.dither()
  |> imagine.colors(8)
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
/// imagine.from_file("portrait.jpg")
/// |> presets.vintage_sepia()
/// |> imagine.to_file("vintage.jpg")
/// ```
///
pub fn vintage_sepia(image: Image) -> Image {
  image
  |> imagine.sepia(80.0)
  |> imagine.contrast_stretch(2.0, 2.0)
  |> imagine.brightness_contrast(-10, 10)
  |> imagine.strip()
}

/// Creates a 1990s web aesthetic with limited color palette.
///
/// Reduces the image to 16 colors with dithering, mimicking the GIF format
/// limitations and dial-up era web graphics.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("banner.jpg")
/// |> presets.web_90s()
/// |> imagine.to_file("retro_web.gif")
/// ```
///
pub fn web_90s(image: Image) -> Image {
  image
  |> imagine.dither()
  |> imagine.colors(16)
}

/// Simulates a halftone newspaper print effect.
///
/// Converts to grayscale and applies angled halftone dots similar to those
/// used in newspaper printing, creating a recognizable vintage print aesthetic.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("photo.jpg")
/// |> presets.newspaper()
/// |> imagine.to_file("newspaper.jpg")
/// ```
///
pub fn newspaper(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.ordered_dither(Halftone8x8Angled)
  |> imagine.contrast_stretch(1.0, 1.0)
}

/// Recreates the degraded quality of VHS tape recordings.
///
/// Applies reduced contrast, warm gamma shift, color posterization, and
/// slight blur to mimic analog video tape artifacts.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("video_frame.jpg")
/// |> presets.vhs()
/// |> imagine.to_file("vhs.jpg")
/// ```
///
pub fn vhs(image: Image) -> Image {
  image
  |> imagine.brightness_contrast(-5, -15)
  |> imagine.gamma(1.2)
  |> imagine.posterize(6)
  |> imagine.blur(0.5)
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
/// imagine.from_file("portrait.jpg")
/// |> presets.pop_art()
/// |> imagine.to_file("pop_art.jpg")
/// ```
///
pub fn pop_art(image: Image) -> Image {
  image
  |> imagine.posterize(3)
  |> imagine.brightness_contrast(0, 30)
  |> imagine.dither()
}

/// Transforms photos into pencil sketch drawings.
///
/// Converts to grayscale, enhances edges with sharpening, and increases
/// contrast to emphasize lines and details like a hand-drawn sketch.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("landscape.jpg")
/// |> presets.sketch()
/// |> imagine.to_file("sketch.jpg")
/// ```
///
pub fn sketch(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.sharpen(2.0)
  |> imagine.auto_level()
  |> imagine.brightness_contrast(10, 40)
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
/// imagine.from_file("portrait.jpg")
/// |> presets.dreamy()
/// |> imagine.to_file("dreamy.jpg")
/// ```
///
pub fn dreamy(image: Image) -> Image {
  image
  |> imagine.blur(1.5)
  |> imagine.brightness_contrast(15, -10)
  |> imagine.gamma(1.1)
}

/// Produces a bright, airy high-key lighting effect.
///
/// Overexposes the image with reduced contrast to create a clean, optimistic,
/// fashion-photography aesthetic with minimal shadows.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("product.jpg")
/// |> presets.high_key()
/// |> imagine.to_file("high_key.jpg")
/// ```
///
pub fn high_key(image: Image) -> Image {
  image
  |> imagine.brightness_contrast(20, -20)
  |> imagine.gamma(1.3)
  |> imagine.normalize()
}

/// Creates dramatic black and white film noir cinematography.
///
/// High contrast grayscale with crushed blacks and bright highlights,
/// evoking classic detective films and dramatic lighting.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("portrait.jpg")
/// |> presets.film_noir()
/// |> imagine.to_file("noir.jpg")
/// ```
///
pub fn film_noir(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.brightness_contrast(-5, 40)
  |> imagine.gamma(0.9)
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
/// imagine.from_file("cityscape.jpg")
/// |> presets.inverted_neon()
/// |> imagine.to_file("neon.jpg")
/// ```
///
pub fn inverted_neon(image: Image) -> Image {
  image
  |> imagine.negate()
  |> imagine.posterize(4)
  |> imagine.brightness_contrast(0, 30)
}

/// Transforms photos into retro pixel art sprites.
///
/// Dramatically downscales with nearest-neighbor filtering, reduces colors,
/// then scales back up to create authentic pixelated game graphics.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("character.jpg")
/// |> presets.pixel_art()
/// |> imagine.to_file("sprite.png")
/// ```
///
pub fn pixel_art(image: Image) -> Image {
  image
  |> imagine.filter(Nearest)
  |> imagine.resize(Percent(25.0))
  |> imagine.dither()
  |> imagine.colors(16)
  |> imagine.filter(Nearest)
  |> imagine.resize(Percent(400.0))
}

/// Creates a high-contrast futuristic cyberpunk aesthetic.
///
/// Enhances brightness and contrast with gamma adjustment and posterization
/// for a neon-soaked, dystopian future look.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("city_night.jpg")
/// |> presets.cyberpunk()
/// |> imagine.to_file("cyberpunk.jpg")
/// ```
///
pub fn cyberpunk(image: Image) -> Image {
  image
  |> imagine.brightness_contrast(10, 35)
  |> imagine.gamma(0.85)
  |> imagine.posterize(5)
}

/// Simulates thermal imaging camera false-color display.
///
/// Converts to grayscale, posterizes, inverts, and auto-levels to mimic
/// the appearance of infrared thermal imaging.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("building.jpg")
/// |> presets.thermal()
/// |> imagine.to_file("thermal.jpg")
/// ```
///
pub fn thermal(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.posterize(8)
  |> imagine.negate()
  |> imagine.auto_level()
}

/// Produces a digital glitch art aesthetic.
///
/// Extreme posterization with circular dithering patterns creates
/// corrupted-data artifacts and digital distortion effects.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("photo.jpg")
/// |> presets.glitch()
/// |> imagine.to_file("glitched.jpg")
/// ```
///
pub fn glitch(image: Image) -> Image {
  image
  |> imagine.posterize(2)
  |> imagine.ordered_dither(Circles7x7Black)
  |> imagine.brightness_contrast(0, 20)
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
/// imagine.from_file("landscape.jpg")
/// |> presets.black_and_white()
/// |> imagine.to_file("bw.jpg")
/// ```
///
pub fn black_and_white(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
}

/// Dramatic high-contrast black and white.
///
/// Pushes blacks and whites to extremes with auto-leveling for maximum
/// visual impact and dramatic mood.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("portrait.jpg")
/// |> presets.high_contrast_bw()
/// |> imagine.to_file("high_contrast.jpg")
/// ```
///
pub fn high_contrast_bw(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.brightness_contrast(0, 40)
  |> imagine.auto_level()
}

/// Gentle, soft grayscale conversion with muted contrast.
///
/// Produces a softer, more subtle black and white look with raised gamma
/// and reduced contrast for a delicate feel.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("portrait.jpg")
/// |> presets.soft_grayscale()
/// |> imagine.to_file("soft_bw.jpg")
/// ```
///
pub fn soft_grayscale(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.gamma(1.2)
  |> imagine.brightness_contrast(5, -10)
}

/// Pure black and white (1-bit) with dithering.
///
/// Converts to true monochrome with only pure black and pure white pixels,
/// using dithering to approximate gray tones. Perfect for bitmap outputs.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("logo.jpg")
/// |> presets.monochrome_dithered()
/// |> imagine.to_file("logo.pbm")
/// ```
///
pub fn monochrome_dithered(image: Image) -> Image {
  image
  |> imagine.monochrome()
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
/// imagine.from_file("sunset.jpg")
/// |> presets.warm_glow()
/// |> imagine.to_file("warm.jpg")
/// ```
///
pub fn warm_glow(image: Image) -> Image {
  image
  |> imagine.gamma(1.1)
  |> imagine.brightness_contrast(10, 5)
}

/// Applies cool, blue-shifted tones for a somber mood.
///
/// Darkens and increases contrast with reduced gamma to create a cold,
/// detached aesthetic common in thriller and sci-fi genres.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("winter.jpg")
/// |> presets.cool_tone()
/// |> imagine.to_file("cool.jpg")
/// ```
///
pub fn cool_tone(image: Image) -> Image {
  image
  |> imagine.gamma(0.95)
  |> imagine.brightness_contrast(-5, 10)
}

/// Creates a washed-out, low-saturation faded look.
///
/// Reduces contrast and increases brightness for a vintage film or
/// Polaroid-style effect with bleached colors.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("photo.jpg")
/// |> presets.faded()
/// |> imagine.to_file("faded.jpg")
/// ```
///
pub fn faded(image: Image) -> Image {
  image
  |> imagine.brightness_contrast(15, -25)
  |> imagine.gamma(1.15)
}

/// Enhances colors and contrast for a vibrant, punchy look.
///
/// Normalizes the image, boosts contrast, and sharpens for maximum visual
/// impact and saturated colors.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("landscape.jpg")
/// |> presets.vibrant()
/// |> imagine.to_file("vibrant.jpg")
/// ```
///
pub fn vibrant(image: Image) -> Image {
  image
  |> imagine.normalize()
  |> imagine.brightness_contrast(5, 25)
  |> imagine.sharpen(0.4)
}

/// Mutes colors for a subtle, desaturated aesthetic.
///
/// Reduces contrast and slightly adjusts gamma for a subdued, sophisticated
/// look popular in minimalist and modern design.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("product.jpg")
/// |> presets.desaturated()
/// |> imagine.to_file("muted.jpg")
/// ```
///
pub fn desaturated(image: Image) -> Image {
  image
  |> imagine.brightness_contrast(0, -20)
  |> imagine.gamma(1.05)
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
/// imagine.from_file("game_scene.jpg")
/// |> presets.gameboy()
/// |> imagine.to_file("gameboy.png")
/// ```
///
pub fn gameboy(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.posterize(2)
  |> imagine.dither()
}

/// Applies the 4-color CGA (Color Graphics Adapter) palette.
///
/// Reduces to 4 colors with extreme posterization and dithering to recreate
/// early 1980s PC graphics.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("scene.jpg")
/// |> presets.cga()
/// |> imagine.to_file("cga.png")
/// ```
///
pub fn cga(image: Image) -> Image {
  image
  |> imagine.dither()
  |> imagine.colors(4)
  |> imagine.posterize(2)
  |> imagine.brightness_contrast(0, 30)
}

/// Creates a blocky teletext/videotex aesthetic.
///
/// Dramatically downscales with reduced colors, then scales back up to
/// create chunky, low-resolution text terminal graphics.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("image.jpg")
/// |> presets.teletext()
/// |> imagine.to_file("teletext.png")
/// ```
///
pub fn teletext(image: Image) -> Image {
  image
  |> imagine.filter(Nearest)
  |> imagine.resize(Percent(20.0))
  |> imagine.colors(8)
  |> imagine.filter(Nearest)
  |> imagine.resize(Percent(500.0))
}

/// Mimics the Commodore 64 16-color palette aesthetic.
///
/// Reduces to 16 colors with moderate posterization and color enhancement
/// to evoke the classic home computer's graphics.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("retro_scene.jpg")
/// |> presets.commodore64()
/// |> imagine.to_file("c64.png")
/// ```
///
pub fn commodore64(image: Image) -> Image {
  image
  |> imagine.dither()
  |> imagine.colors(16)
  |> imagine.posterize(4)
  |> imagine.brightness_contrast(5, 15)
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
/// imagine.from_file("photo.jpg")
/// |> presets.grainy()
/// |> imagine.to_file("grainy.jpg")
/// ```
///
pub fn grainy(image: Image) -> Image {
  image
  |> imagine.ordered_dither(Ordered3x3)
  |> imagine.brightness_contrast(0, 5)
}

/// Creates ultra-smooth, denoised appearance.
///
/// Applies blur followed by normalization and light sharpening to reduce
/// noise while maintaining edge definition.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("noisy_photo.jpg")
/// |> presets.smooth()
/// |> imagine.to_file("smooth.jpg")
/// ```
///
pub fn smooth(image: Image) -> Image {
  image
  |> imagine.blur(0.5)
  |> imagine.normalize()
  |> imagine.sharpen(0.2)
}

/// Applies color halftone printing effect.
///
/// Uses orthogonal halftone dithering to simulate CMYK printing dot patterns
/// visible in magazines and color printing.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("photo.jpg")
/// |> presets.halftone_color()
/// |> imagine.to_file("halftone.jpg")
/// ```
///
pub fn halftone_color(image: Image) -> Image {
  image
  |> imagine.ordered_dither(Halftone6x6Orthogonal)
  |> imagine.brightness_contrast(0, 10)
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
/// imagine.from_file("portrait.jpg")
/// |> presets.comic_book()
/// |> imagine.to_file("comic.jpg")
/// ```
///
pub fn comic_book(image: Image) -> Image {
  image
  |> imagine.posterize(5)
  |> imagine.sharpen(1.0)
  |> imagine.brightness_contrast(0, 35)
  |> imagine.auto_level()
}

/// Simulates soft watercolor painting.
///
/// Applies blur with posterization and reduced contrast to create a fluid,
/// painted-on-paper aesthetic with bleeding colors.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("landscape.jpg")
/// |> presets.watercolor()
/// |> imagine.to_file("watercolor.jpg")
/// ```
///
pub fn watercolor(image: Image) -> Image {
  image
  |> imagine.blur(2.0)
  |> imagine.posterize(8)
  |> imagine.brightness_contrast(10, -15)
}

/// Creates textured oil painting effect.
///
/// Combines posterization with moderate blur and contrast boost to simulate
/// thick brush strokes and paint texture.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("portrait.jpg")
/// |> presets.oil_painting()
/// |> imagine.to_file("oil.jpg")
/// ```
///
pub fn oil_painting(image: Image) -> Image {
  image
  |> imagine.posterize(6)
  |> imagine.blur(1.0)
  |> imagine.brightness_contrast(5, 15)
}

/// Produces charcoal sketch drawing effect.
///
/// Converts to grayscale with extreme sharpening and contrast to emphasize
/// edges and create a hand-drawn charcoal aesthetic.
///
/// ## Example
///
/// ```gleam
/// imagine.from_file("portrait.jpg")
/// |> presets.charcoal()
/// |> imagine.to_file("charcoal.jpg")
/// ```
///
pub fn charcoal(image: Image) -> Image {
  image
  |> imagine.colorspace(imagine.Gray)
  |> imagine.sharpen(3.0)
  |> imagine.brightness_contrast(-10, 50)
}
