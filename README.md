# Noctalia Smart Calculator

A Raycast-style calculator plugin for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) powered by [libqalculate](https://qalculate.github.io/).

Type math expressions, unit conversions, and currency exchanges directly in the Noctalia launcher.

## Features

- **Math expressions**: `2^10`, `sqrt(144)`, `sin(45 deg)`, `log(1000)`
- **Unit conversions**: `10 km to miles`, `72 fahrenheit to celsius`, `500 ml to cups`
- **Mixed unit math**: `23 m + 4 m + 7 km`, `56 km/hr to m/s`
- **Currency exchange**: `100 USD to EUR`, `50 GBP to JPY` (live rates via libqalculate)
- **Smart defaults**: Type `36 km/h` and get `m/s` automatically; type `100 USD` and get `EUR`
- **Context-aware icons**: Different icons for currency, speed, temperature, weight, etc.

Press **Enter** to copy the result to clipboard.

## Requirements

- [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) >= 3.6.0
- [libqalculate](https://qalculate.github.io/) (`qalc` CLI must be in PATH)
- `wl-copy` (from wl-clipboard, for copying results)

### NixOS

```nix
home.packages = with pkgs; [ libqalculate ];
```

## Installation

### Manual

Copy the plugin directory to your Noctalia plugins folder:

```bash
mkdir -p ~/.config/noctalia/plugins
cp -r . ~/.config/noctalia/plugins/smart-calculator
```

Then enable it in `~/.config/noctalia/plugins.json`:

```json
{
  "smart-calculator": {
    "enabled": true,
    "version": "1.0.0"
  }
}
```

Restart Noctalia to load the plugin.

### NixOS / Home Manager

Add the plugin as a flake input and deploy the files via home-manager. See the [NixOS integration example](https://github.com/nickcomua/noctalia-smart-calculator#nixos--home-manager) for details.

## Supported Conversions

| Category    | Examples                                              |
|-------------|-------------------------------------------------------|
| Length      | mm, cm, m, km, in, ft, yd, mi, nmi                   |
| Weight      | mg, g, kg, t, oz, lb, st                              |
| Volume      | ml, l, gal, qt, pt, cup, fl oz, tbsp, tsp            |
| Area        | mm², cm², m², km², in², ft², acre, hectare            |
| Speed       | m/s, km/h, mph, ft/s, knots                          |
| Temperature | °C, °F, K, celsius, fahrenheit, kelvin                |
| Time        | ms, s, min, h, d, wk, mo, yr                         |
| Data        | b, B, KB, MB, GB, TB, KiB, MiB, GiB, TiB            |
| Energy      | J, kJ, cal, kcal, Wh, kWh, BTU, eV                   |
| Currency    | 150+ currencies (USD, EUR, GBP, JPY, ...) with live rates |

Plus everything else supported by [libqalculate](https://qalculate.github.io/features.html).

## License

MIT
