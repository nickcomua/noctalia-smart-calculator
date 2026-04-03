import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  // Provider metadata
  property string name: "Smart Calculator"
  property var launcher: null
  property string iconMode: "tabler"
  property bool handleSearch: true
  property string supportedLayouts: "list"

  // Result cache: maps query string -> result string
  property string cachedQuery: ""
  property string cachedResult: ""

  // Default conversion targets (SI/metric for units, EUR for currency)
  readonly property var defaultTargets: ({
    "km/h": "m/s", "km/hr": "m/s", "kph": "m/s", "kmh": "m/s",
    "mph": "m/s", "mi/h": "m/s", "mi/hr": "m/s",
    "ft/s": "m/s", "fps": "m/s",
    "knot": "m/s", "knots": "m/s", "kn": "m/s", "kt": "m/s",
    "km": "m", "miles": "m", "mile": "m", "mi": "m",
    "ft": "m", "feet": "m", "foot": "m",
    "yd": "m", "yard": "m", "yards": "m",
    "in": "cm", "inch": "cm", "inches": "cm",
    "nmi": "m",
    "gal": "l", "gallon": "l", "gallons": "l",
    "qt": "l", "quart": "l", "quarts": "l",
    "pt": "l", "pint": "l", "pints": "l",
    "cup": "ml", "cups": "ml", "floz": "ml",
    "acre": "m^2", "acres": "m^2",
    "hectare": "m^2", "hectares": "m^2", "ha": "m^2",
    "sqft": "m^2", "sqmi": "km^2",
    "cal": "J", "kcal": "kJ",
    "btu": "J", "BTU": "J", "eV": "J",
    "kB": "MB", "MB": "GB", "GB": "TB",
    "KiB": "MiB", "MiB": "GiB", "GiB": "TiB"
  })

  readonly property var currencyCodes: [
    "USD","EUR","GBP","JPY","CNY","INR","KRW","RUB","UAH","TRY",
    "PLN","SEK","NOK","DKK","BRL","CHF","AUD","CAD","NZD","SGD",
    "HKD","MXN","CZK","RON","BGN","HUF","ILS","THB","PHP","IDR",
    "MYR","SAR","AED","ZAR","EGP","NGN","PKR","BDT","VND","ARS",
    "COP","CLP","PEN","UYU","BOB","TWD"
  ]

  function applyDefaultTarget(query) {
    var trimmed = query.trim();
    if (/\b(to|in)\b/i.test(trimmed)) return null;

    var lower = trimmed.toLowerCase();
    for (var unit in defaultTargets) {
      var escapedUnit = unit.replace(/\//g, "\\/");
      var re = new RegExp("\\b" + escapedUnit + "\\s*$", "i");
      if (re.test(lower)) {
        return trimmed + " to " + defaultTargets[unit];
      }
    }

    var currMatch = lower.match(/\b([a-z]{3})\s*$/);
    if (currMatch) {
      var code = currMatch[1].toUpperCase();
      if (currencyCodes.indexOf(code) >= 0) {
        return trimmed + " to " + (code === "EUR" ? "USD" : "EUR");
      }
    }

    if (/^[\$\u20ac\u00a3\u00a5\u20b9\u20a9\u20bd\u20bf\u20b4\u20ba]/.test(trimmed)) {
      return trimmed + " to " + (trimmed.charAt(0) === "\u20ac" ? "USD" : "EUR");
    }

    return null;
  }

  function isCalculatable(query) {
    var trimmed = query.trim();
    if (trimmed.length < 2) return false;
    if (!/[\d]/.test(trimmed)) return false;
    return true;
  }

  function chooseIcon(query, result) {
    var combined = query + " " + result;
    if (/[\$\u20ac\u00a3\u00a5\u20b9\u20a9\u20bd\u20bf\u20b4\u20ba]|USD|EUR|GBP|JPY/.test(combined)) return "currency-dollar";
    if (/\b(m\/s|km\/h|mph|knot|ft\/s)\b/.test(combined)) return "gauge";
    if (/\b(kg|lb|oz|gram|ton)\b/i.test(combined)) return "scale";
    if (/[°]?[CF]\b|fahrenheit|celsius|kelvin/.test(combined)) return "temperature";
    if (/\b(liter|gallon|ml|cup|pint|floz)\b/i.test(combined)) return "droplet";
    if (/\b(byte|bit|[KMGT]i?B)\b/.test(combined)) return "database";
    if (/\b(meter|foot|feet|mile|inch|yard|km|cm|mm)\b/i.test(combined)) return "ruler-measure";
    return "calculator";
  }

  // Async qalc process
  Process {
    id: qalcProc
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: (exitCode) => {
      if (exitCode === 0) {
        var result = stdout.text.trim();
        if (result && result !== "0" || root.cachedQuery.trim() === "0") {
          root.cachedResult = result;
          // Trigger launcher to re-query providers, picking up our cached result
          if (root.launcher && typeof root.launcher.updateResults === "function") {
            root.launcher.updateResults();
          }
        }
      }
    }
  }

  // Debounce: wait for user to stop typing before running qalc
  Timer {
    id: debounce
    interval: 120
    repeat: false
    property string pendingQuery: ""
    onTriggered: {
      if (pendingQuery) {
        qalcProc.command = ["qalc", "-t", "-set", "decimal_comma off", pendingQuery];
        qalcProc.running = true;
      }
    }
  }

  function getResults(query) {
    if (!query) return [];
    var trimmed = query.trim();
    if (!isCalculatable(trimmed)) return [];

    var enhanced = applyDefaultTarget(trimmed);
    var finalQuery = enhanced || trimmed;

    // If we have a cached result for this exact query, return it
    if (finalQuery === root.cachedQuery && root.cachedResult) {
      var icon = chooseIcon(finalQuery, root.cachedResult);
      var displayResult = root.cachedResult;
      return [{
        "name": displayResult,
        "description": trimmed + " = " + displayResult + "  \u00b7  Press Enter to copy",
        "icon": icon,
        "isTablerIcon": true,
        "isImage": false,
        "provider": root,
        "onActivate": function() {
          Quickshell.execDetached(["sh", "-c", "printf '%s' '" + displayResult.replace(/'/g, "'\\''") + "' | wl-copy"]);
          if (launcher) launcher.close();
        }
      }];
    }

    // Query changed -- fire async qalc and return empty for now
    root.cachedQuery = finalQuery;
    root.cachedResult = "";
    debounce.pendingQuery = finalQuery;
    debounce.restart();
    return [];
  }
}
