"""Repack NASA LOLA uint16 TIFF to a lossless two-channel elevation texture.

Source URL and units are documented in README.md. Requires Pillow and numpy.
Usage: python assets/moon/prepare_height.py path/to/ldem_16_uint.tif
"""
from pathlib import Path
import sys
import numpy as np
from PIL import Image

source = Image.open(sys.argv[1]).convert("I")
height = np.asarray(source.resize((2048, 1024), Image.Resampling.LANCZOS))
height = np.clip(height, 0, 65535).astype("uint16")
packed = np.zeros((1024, 2048, 3), dtype="uint8")
packed[:, :, 0] = height // 256
packed[:, :, 1] = height % 256
Image.fromarray(packed).save(Path(__file__).with_name("lola_height_2k.png"))
