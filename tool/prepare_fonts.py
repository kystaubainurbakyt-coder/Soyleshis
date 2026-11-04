"""Create offline, Kazakh-capable static fonts from the OFL source assets."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

root = Path(__file__).resolve().parents[1] / 'assets' / 'fonts'
required = [0x04D8, 0x04D9, 0x0492, 0x0493, 0x049A, 0x049B, 0x04A2,
            0x04A3, 0x04E8, 0x04E9, 0x04B0, 0x04B1, 0x04AE, 0x04AF,
            0x04BA, 0x04BB, 0x0406, 0x0456]
characters = list(range(0x20, 0x250)) + list(range(0x400, 0x530)) + list(range(0x2000, 0x2070)) + list(range(0x20A0, 0x2150))

def prepare(source, target, weight):
    font = TTFont(root / source)
    if 'fvar' in font:
        axes = {axis.axisTag: axis.defaultValue for axis in font['fvar'].axes}
        axes['wght'] = weight
        font = instantiateVariableFont(font, axes, inplace=True)
    assert all(c in font.getBestCmap() for c in required), 'Missing Kazakh glyphs'
    options = subset.Options()
    options.name_IDs = ['*']
    sub = subset.Subsetter(options=options)
    sub.populate(unicodes=characters)
    sub.subset(font)
    font.save(root / target)
    print(target, (root / target).stat().st_size)

for weight, name in [(400, 'Regular'), (600, 'SemiBold'), (700, 'Bold'), (800, 'ExtraBold')]:
    prepare('NotoSans-source.ttf', f'NotoSans-{name}.ttf', weight)
prepare('NotoSerif.ttf', 'NotoSerif.ttf', 400)
