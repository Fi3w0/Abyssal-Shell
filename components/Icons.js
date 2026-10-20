.pragma library

// Abyssal's own line icons: 24x24 grid, 2px round strokes, no fill. Each
// entry is the inner SVG; url() wraps it with the requested colour.

var paths = {
    "logo":            '<path d="M3 9c2.5-2 4.5-2 7 0s4.5 2 7 0 3-1.5 4-1"/><path d="M3 15c2.5-2 4.5-2 7 0s4.5 2 7 0 3-1.5 4-1"/>',
    "moon":            '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>',
    "wifi":            '<path d="M2 9a15 15 0 0 1 20 0"/><path d="M5 12.5a10 10 0 0 1 14 0"/><path d="M8.5 16a5 5 0 0 1 7 0"/><path d="M12 19.5h.01"/>',
    "wifi-off":        '<path d="M8.5 16a5 5 0 0 1 7 0"/><path d="M12 19.5h.01"/><path d="M3 3l18 18"/><path d="M5 12.5a10 10 0 0 1 4.5-2.7"/><path d="M2 9a15 15 0 0 1 4.3-2.8"/>',
    "ethernet":        '<path d="M4 6h16v10H4z"/><path d="M8 16v4M12 16v4M16 16v4"/><path d="M8 10h8"/>',
    "bluetooth":       '<path d="M7 7l10 10-5 5V2l5 5L7 17"/>',
    "volume-high":     '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>',
    "volume-low":      '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>',
    "volume-mute":     '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M22 9l-6 6"/><path d="M16 9l6 6"/>',
    "power":           '<path d="M12 3v8"/><path d="M6.3 7.5a8 8 0 1 0 11.4 0"/>',
    "lock":            '<path d="M5 11h14v10H5z"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
    "logout":          '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>',
    "sleep":           '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/><path d="M15 3h4l-4 5h4"/>',
    "reboot":          '<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>',
    "cpu":             '<path d="M6 6h12v12H6z"/><path d="M10 10h4v4h-4z"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/>',
    "memory":          '<path d="M3 7h18v9H3z"/><path d="M7 10v3M11 10v3M15 10v3"/><path d="M6 16v3M10 16v3M14 16v3M18 16v3"/>',
    "thermometer":     '<path d="M14 14.8V4a2 2 0 0 0-4 0v10.8a4 4 0 1 0 4 0z"/>',
    "battery":         '<path d="M3 8h15v8H3z"/><path d="M21 11v2"/><path d="M6 11v2M9 11v2"/>',
    "battery-low":     '<path d="M3 8h15v8H3z"/><path d="M21 11v2"/><path d="M6 11v2"/>',
    "battery-charging":'<path d="M3 8h15v8H3z"/><path d="M21 11v2"/><path d="M11 9.5l-2 2.5h3l-2 2.5"/>',
    "record":          '<path d="M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z"/><path d="M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z"/>',
    "bell":            '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>',
    "x":               '<path d="M18 6L6 18M6 6l12 12"/>',
    "chevron-left":    '<path d="M15 18l-6-6 6-6"/>',
    "chevron-right":   '<path d="M9 18l6-6-6-6"/>',
    "check":           '<path d="M20 6L9 17l-5-5"/>',
    "square":          '<path d="M5 5h14v14H5z"/>',
    "app":             '<path d="M3 5h18v14H3z"/><path d="M3 9h18"/>',
    "search":          '<path d="M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14z"/><path d="M20 20l-4-4"/>',
    "grid":            '<path d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z"/>',
    "sliders":         '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><path d="M14 4v4M8 10v4M16 16v4"/>',
    "plus":            '<path d="M12 5v14M5 12h14"/>',
    "minus":           '<path d="M5 12h14"/>',
    "trash":           '<path d="M4 7h16"/><path d="M10 11v6M14 11v6"/><path d="M6 7l1 13h10l1-13"/><path d="M9 7V4h6v3"/>',
    "pencil":          '<path d="M4 20h4L19 9l-4-4L4 16v4z"/><path d="M13.5 6.5l4 4"/>',
    "grip":            '<path d="M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01"/>',
    "bell-off":        '<path d="M6 8a6 6 0 0 1 9.5-4.9M18 8c0 7 3 9 3 9H9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/><path d="M3 3l18 18"/>',
    "coffee":          '<path d="M4 9h13v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V9z"/><path d="M17 11h1.5a2.5 2.5 0 0 1 0 5H17"/><path d="M8 3v3M12 3v3"/>',
    "mic":             '<path d="M9 5a3 3 0 0 1 6 0v6a3 3 0 0 1-6 0V5z"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>',
    "mic-off":         '<path d="M15 9.3V5a3 3 0 0 0-5.7-1.3"/><path d="M9 9v2a3 3 0 0 0 4.6 2.5"/><path d="M5 11a7 7 0 0 0 11.5 5.4M19 11c0 .8-.1 1.6-.4 2.3"/><path d="M12 18v3"/><path d="M3 3l18 18"/>',
    "user":            '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    "layout":          '<path d="M3 4h18v16H3z"/><path d="M3 9h18"/><path d="M9 9v11"/>',
    "arrow-up":        '<path d="M12 19V5M5 12l7-7 7 7"/>',
    "arrow-down":      '<path d="M12 5v14M5 12l7 7 7-7"/>',
    "arrow-left":      '<path d="M19 12H5M12 5l-7 7 7 7"/>',
    "arrow-right":     '<path d="M5 12h14M12 5l7 7-7 7"/>',
    "dot":             '<path d="M12 11.5v1"/>'
};

function url(name, color, stroke) {
    var inner = paths[name] || paths["square"];
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + color
            + '" stroke-width="' + stroke + '" stroke-linecap="round" stroke-linejoin="round">' + inner + '</svg>';
    return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
}
