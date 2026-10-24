# Linux Typography & Global Font Architecture: Why Non-Latin Scripts Break and How We Fixed It

This document details the root cause behind broken or deformed non-Latin (Indic, Arabic, CJK, etc.) typography across various Linux distributions (NixOS, Debian, Ubuntu), compares it to Fedora Workstation's pristine rendering pipeline, and documents the declarative, Fedora-grade font engine implemented in `nixos-config`.

---

## 1. Executive Summary: The Root Cause

When rendering non-Latin text (such as Bengali `শনি অক্টোবর 24`), desktop shells (GNOME Shell) and applications often display misshapen glyphs, broken conjuncts (যুক্তাক্ষর), and uneven stroke weights.

The issue is **not** a missing font or an incorrect font size. Rather, it is a **fallback hijacking bug caused by GNU FreeFont (`FreeSans.ttf` / `FreeSerif.ttf`)**:

1. **Obsolete Font Data**: GNU FreeFont is an unmaintained font package from 2012 (with glyph data dating to the early 2000s). It contains rudimentary glyph outlines for many Unicode blocks (Bengali, Devanagari, Gujarati, Gurmukhi, Malayalam, Tamil, Telugu, Kannada, Sinhala, Arabic, Hebrew, Ethiopic, etc.), but **completely lacks modern OpenType Layout tables (`GSUB` / `GPOS`)** required by text-shaping engines (HarfBuzz) to assemble complex ligatures and vowel marks.
2. **Unintentional Fontconfig Promotion**: Default upstream fontconfig ships `/etc/fonts/conf.d/69-unifont.conf`, which injects `FreeSans` into the generic `sans-serif` `<prefer>` list.
3. **The Fallback Trap**: When an interface font (like GNOME's `Adwaita Sans` or `Cantarell`) lacks non-Latin glyphs, fontconfig falls back through `sans-serif`. Because `FreeSans` is explicitly in the fallback list and claims Unicode coverage for those codepoints, **fontconfig selects `FreeSans.ttf` before modern fonts (like Google Noto)**.
4. **Why Fedora Looks Pristine**: Fedora Workstation **never ships GNU FreeFont** in its default installations and packages all Noto fonts with explicit language-aware fontconfig rules (`conf.avail/65-*.conf`) that force fontconfig to prepend Noto fonts over any generic fallback.

---

## 2. Deep Dive: Text Shaping & Font Matching

Understanding why fonts look deformed requires understanding how Linux renders text:

```
[ Application / GNOME Shell ] (Adwaita Sans 11)
             │
             ▼
[ Pango Layout Engine ] ─── Breaks text into localized runs (e.g. English + Bengali)
             │
             ▼
[ Fontconfig Resolution ] ── Queries font cache for best matching font covering run
             │
      ┌──────┴──────────────────────────────────────┐
      │ Fails on Adwaita Sans (no Bengali glyphs)    │
      │ Traverses fallback chain                    │
      └──────┬──────────────────────────────────────┘
             │
      ┌──────┴───────────────────────────────────────────────────────┐
      │ BROKEN DEFAULT (NixOS / Debian / Ubuntu):                   │
      │ 1. 69-unifont.conf injects "FreeSans" into sans-serif list   │
      │ 2. FreeSans claims coverage for U+0980..U+09FF              │
      │ 3. Fontconfig selects FreeSans.ttf                          │
      └──────┬───────────────────────────────────────────────────────┘
             │
             ▼
[ HarfBuzz Shaping Engine ] ── Attempts to form conjuncts (e.g. ক্ + ট = ক্ট)
             │
      ┌──────┴───────────────────────────────────────────────────────┐
      │ FreeSans has NO GSUB ligatures for "ক্ট"                    │
      │ FreeSans has archaic, deformed standalone outlines           │
      │ Result: Broken, misshapen glyphs rendered on screen         │
      └──────────────────────────────────────────────────────────────┘
```

When HarfBuzz shapes text with **Noto Sans Bengali**, it uses modern OpenType `bng2` / `beng` shaping tables to render seamless conjuncts, correct matra (vowel sign) reordering, and balanced stroke metrics. With FreeSans, it has no rules to apply, resulting in disjointed, broken characters.

---

## 3. Comparative Architecture: Fedora vs NixOS / Debian / Ubuntu

| Component | Debian / Ubuntu / Stock NixOS | Fedora Workstation | Our NixOS Flake (`system/fonts.nix`) |
|---|---|---|---|
| **Default Unicode Bundle** | Installs `freefont-ttf` / `fonts-freefont-ttf` via default metapackages | Excluded completely | `enableDefaultPackages = false;` (FreeFont purged) |
| **Fallback Preference** | `69-unifont.conf` adds `FreeSans` to `sans-serif` | FreeFont absent; Noto prioritized at priority 56–67 | `<selectfont><rejectfont>` permanently blacklists FreeFont |
| **Interface Font Aliasing** | `Adwaita Sans` / `Cantarell` unaliased to script fallbacks | Aliased via `59-adwaita-sans-fonts.conf` | Explicit aliases mapping `Adwaita Sans` & `Cantarell` to `sans-serif` |
| **Language-Aware Overrides** | Missing for most Indic/Asian scripts | Ships `65-0-google-noto-*-vf.conf` per language pack | Explicit `localConf` rules for `bn`, `hi`, `ar`, `ja`, `ko`, `zh`, etc. |
| **Primary Fallback Font** | `FreeSans.ttf` (Broken) | `NotoSans*.ttf` (Pristine) | `NotoSans*.ttf` (Pristine) |

---

## 4. Fontconfig Priority Architecture

Fontconfig processes XML configuration files in numerical priority order:

1. **`10`–`29` (Rendering & Rasterization)**: Antialiasing, subpixel layout (`rgba`), hinting, LCD filter.
2. **`30`–`49` (Metric Aliases & Generic Substitutions)**: Substitutes metric-compatible fonts (e.g., Liberation for Arial).
3. **`50` (`50-user.conf`)**: User configuration (`~/.config/fontconfig/fonts.conf`).
4. **`51` (`51-local.conf`)**: System-wide `localConf` (`/etc/fonts/local.conf`). **This is where our custom engine injects rules.**
5. **`52` (`52-nixos-default-fonts.conf`)**: NixOS default fonts (`fonts.fontconfig.defaultFonts`).
6. **`60`–`64` (Generic Family Preferences)**: General Latin/Symbol mappings.
7. **`65` (`65-nonlatin.conf`)**: Upstream non-Latin script mappings.
8. **`69` (`69-unifont.conf`)**: Injects FreeFont and unifont as catch-all fallbacks.

Because our configuration is injected at **Priority 51 (`localConf`)**, our rules take precedence over `52-nixos-default-fonts.conf`, `65-nonlatin.conf`, and `69-unifont.conf`.

---

## 5. Implementation in `nixos-config`

Our unified font engine lives in [`system/fonts.nix`](file:///home/faeizmahrus/Projects/nixos-config/system/fonts.nix) and is imported globally via [`system/default.nix`](file:///home/faeizmahrus/Projects/nixos-config/system/default.nix).

### Key Features of the Implementation:

1. **Purging GNU FreeFont**:
   `fonts.enableDefaultPackages = false;` prevents Nixpkgs from injecting `pkgs.freefont_ttf`.
2. **Clean Unicode & Typography Baseline**:
   Explicitly installs modern equivalents:
   - `pkgs.dejavu_fonts`, `pkgs.liberation_ttf`, `pkgs.gyre-fonts`, `pkgs.unifont`
   - `pkgs.adwaita-fonts` (Official GNOME 48+ typeface)
   - `pkgs.corefonts` (Microsoft TrueType compatibility)
3. **Maximum Unicode Archive**:
   - `pkgs.noto-fonts` (Comprehensive living world scripts & unicode coverage)
   - `pkgs.noto-fonts-cjk-sans` & `pkgs.noto-fonts-cjk-serif` (Chinese, Japanese, Korean)
   - `pkgs.noto-fonts-color-emoji` (Emoji)
   - `pkgs.lohit-fonts.bengali` (Curated Indic fallback)
4. **Explicit Blacklist (`<rejectfont>`)**:
   Even if a Flatpak, Distrobox container, or third-party tool brings `FreeSans`, `FreeSerif`, or `FreeMono`, fontconfig is instructed to unconditionally reject them:
   ```xml
   <selectfont>
     <rejectfont>
       <pattern><patelt name="family"><string>FreeSans</string></patelt></pattern>
       <pattern><patelt name="family"><string>FreeSerif</string></patelt></pattern>
       <pattern><patelt name="family"><string>FreeMono</string></patelt></pattern>
     </rejectfont>
   </selectfont>
   ```
5. **Fedora-Grade Language-Specific Precedence**:
   Explicit match rules for global languages (`bn`, `hi`, `ar`, `fa`, `ur`, `ja`, `ko`, `zh-cn`, `zh-tw`) that automatically route text to the appropriate Noto font family.

---

## 6. Verification & Troubleshooting Runbook

To inspect font resolution on any Linux machine or container:

### 1. Check What Font Matches a Specific Language
```sh
fc-match -s "sans-serif:lang=bn" | head -n 5
fc-match -s "Adwaita Sans:lang=bn" | head -n 5
```
*Expected: `NotoSansBengali.ttf` or `NotoSans*.ttf` should appear at the top of the non-Latin list.*

### 2. Check Fallback for Specific Unicode Characters
```sh
# Bengali test: শনি অক্টোবর (Codepoints 9b6 9a8 9bf 985 995 9cd 99f 9cb 9ac 9b0)
fc-match "Adwaita Sans:charset=9b6 9a8 9bf 985 995 9cd 99f 9cb 9ac 9b0"
```
*Expected: `NotoSansBengali.ttf: "Noto Sans Bengali" "Regular"` (NOT `FreeSans.ttf`).*

### 3. Debug Rule Processing
To see every fontconfig rule applied during pattern evaluation:
```sh
FC_DEBUG=4 fc-match "sans-serif:lang=bn" 2>&1 | grep -E "Rule Set|Substitute Edit"
```

To see the score calculation determining which font won:
```sh
FC_DEBUG=1 fc-match "sans-serif:charset=9b6"
```
