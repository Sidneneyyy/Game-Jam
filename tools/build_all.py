"""Regenerate every asset: python tools/build_all.py"""
import draw_creatures
import draw_park
import draw_ui
import make_sounds

draw_creatures.build()
draw_park.build()
draw_ui.build()
make_sounds.sfx()
make_sounds.music()
print("all assets built")
