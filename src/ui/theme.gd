class_name UITheme
## Shared UI color and layout constants for the Dungeon Steward UI.
## All UI controllers should import colors from here instead of defining
## their own inline Color() values.

# ── Core palette ──────────────────────────────────────────────────────
const PANEL_BG := Color("#1a1520")
const PANEL_BORDER := Color("#4b3860")
const ARENA_BG := Color("#0e0a14")

# ── Typography ────────────────────────────────────────────────────────
const TEXT_PRIMARY := Color("#fffdf5")
const TEXT_MUTED := Color("#a0a8b8")
const TEXT_ACCENT := Color("#60d0ff")
const TEXT_GOOD := Color("#70e870")
const TEXT_WARN := Color("#ffd36a")
const TEXT_BAD := Color("#ff6666")

# ── HP bars ───────────────────────────────────────────────────────────
const HP_PLAYER := Color("#50c860")
const HP_ENEMY := Color("#e05050")

# ── Energy / Block ────────────────────────────────────────────────────
const ENERGY_COLOR := Color("#60a0e0")
const BLOCK_COLOR := Color("#60d0ff")

# ── Card body ─────────────────────────────────────────────────────────
const CARD_BODY := Color("#eadfc7")
const CARD_BODY_DISABLED := Color("#938b7e")
const CARD_BORDER := Color("#5a4733")
const CARD_BORDER_ATTACK := Color("#c04040")
const CARD_BORDER_DEFEND := Color("#4080c0")
const CARD_BORDER_UTILITY := Color("#c09030")

# ── Card inner regions ────────────────────────────────────────────────
const CARD_TITLE_BG := Color("#33261a")
const CARD_TITLE_TEXT := Color("#f7efe2")
const CARD_TEXT := Color("#2c2218")
const CARD_TEXT_MUTED := Color("#6d5d49")
const CARD_COST_BG := Color("#2a2040")
const CARD_COST_TEXT := Color("#e0d8f0")
const CARD_ART_BG := Color("#c8bda5")
const CARD_FOOTER_LOCKED := Color("#402020")

# ── Map nodes ─────────────────────────────────────────────────────────
const NODE_RUBY := Color("#e04040")
const NODE_SAPPHIRE := Color("#3090e0")
const NODE_NEUTRAL := Color("#707880")
const NODE_CLEARED := Color("#383040")
const NODE_CURRENT := Color("#f0c030")
const NODE_LEGAL_RING := Color("#e0b840")
const EDGE_DEFAULT := Color("#403848")
const EDGE_LEGAL := Color("#60d0ff")

# ── Card layout ───────────────────────────────────────────────────────
const CARD_WIDTH := 320.0
const CARD_HEIGHT := 440.0
const CARD_OVERLAP := 200.0
const CARD_HOVER_LIFT := 60.0
const CARD_HOVER_SCALE := 1.15
const NODE_RADIUS := 72.0
