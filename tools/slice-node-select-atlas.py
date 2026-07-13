"""node_select 시트 4장에서 atlas 리소스 조각을 잘라낸다. 1회 실행 도구."""
from pathlib import Path
from PIL import Image

BASE = Path(__file__).resolve().parents[1] / "app-LTL" / "resources" / "node_select"
ATLAS = BASE / "atlas"
MANIFEST = [
    ("cta_button_styles_ltl_route_select.png", (186, 54, 1072, 257), "btn_stone_leaf_primary.png"),
    ("cta_button_styles_ltl_route_select.png", (165, 612, 1119, 245), "chip_ruin_tablet.png"),
    ("cta_button_styles_ltl_route_select.png", (261, 893, 476, 155), "btn_parchment_secondary.png"),
    ("cta_button_styles_ltl_route_select.png", (809, 892, 362, 160), "btn_folio_secondary.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (69, 73, 406, 433), "icon_battle_gate.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (529, 73, 386, 430), "icon_event_leaf.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (974, 95, 405, 411), "icon_reward_geode.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (68, 553, 392, 433), "icon_camp_seed.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (508, 518, 433, 487), "icon_boss_crest.png"),
    ("node_icon_sheet_ltl_ruin_biome.png", (984, 544, 397, 446), "icon_locked_roots.png"),
    ("inspector_panel_styles_ltl_field_notes.png", (8, 16, 551, 884), "panel_atlas.png"),
]

for sheet_name, (x, y, w, h), out_name in MANIFEST:
    sheet = Image.open(BASE / sheet_name).convert("RGBA")
    sheet.crop((x, y, x + w, y + h)).save(ATLAS / out_name)
    print(f"{out_name}: {w}x{h}")
