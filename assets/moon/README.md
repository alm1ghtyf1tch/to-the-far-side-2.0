# Lunar surface data

Credit: **NASA's Scientific Visualization Studio**, Ernie Wright; LRO camera
(LROC / Arizona State University) and Lunar Orbiter Laser Altimeter (LOLA) teams.

Source: [CGI Moon Kit, 6 September 2019](https://svs.gsfc.nasa.gov/4720/).
These are publicly released NASA scientific visualization/data assets, used under
[NASA imagery and media usage guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/),
not a Creative Commons asset pack. NASA attribution is retained; no NASA insignia,
endorsement, or proprietary game artwork is included. The source page identifies
the underlying LROC mosaic and LOLA data and requests the credit above.
The LROC team's [terms and citation policy](https://www.lroc.im-ldi.com/about/terms)
also identifies released PDS data products as public domain, with NASA/GSFC/ASU
credit. No separate restrictive license is indicated on the CGI Moon Kit assets.

- `lroc_color_2k.jpg`: original 2048×1024 NASA download, unmodified.
  https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/lroc_color_2k.jpg
- `lola_height_2k.png`: derived numeric data, 2048×1024, from
  https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/ldem_16_uint.tif
  The original is 5760×2880 unsigned 16-bit elevation, units **half metres above
  radius 1727400 m**. Thus elevation relative to the 1737.4 km reference sphere is
  `raw * 0.0005 - 10` km. Resampled with Lanczos, clamped to uint16 and packed into
  lossless RG8: `raw = red_byte * 256 + green_byte`; blue is unused. Import uses
  lossless compression, no sRGB conversion, no VRAM block compression.
- `prepare_height.py` reproduces that conversion with Python, Pillow and numpy.
  The 33 MB source TIFF is not shipped. Download it outside the exported game and
  pass its local filename to the script.

Both maps are equirectangular, longitude −180° at left, 0° at centre, +180° at
right, north at top. They share the same projection. Shader relief is exaggerated
**2.2×** for readability. Surface tint, illumination and edge light are artistic;
the edge light is not an atmosphere. The presentation does not simulate mission
illumination dates and never affects the scientific calculations.
