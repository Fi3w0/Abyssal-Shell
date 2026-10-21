import QtQuick

Canvas {
    id: frame
    property color fill: Theme.current.panel
    property color edge: Theme.current.line
    property real cut: 16
    property real rounding: 0
    property color lowerFill: fill
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillChanged: requestPaint()
    onEdgeChanged: requestPaint()
    onCutChanged: requestPaint()
    onRoundingChanged: requestPaint()
    onLowerFillChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.beginPath();
        const r = Math.min(rounding, cut * 0.45);
        ctx.moveTo(cut + r, 0.5);
        ctx.lineTo(width - r - 0.5, 0.5);
        ctx.quadraticCurveTo(width - 0.5, 0.5, width - 0.5, r + 0.5);
        ctx.lineTo(width - 0.5, height - cut - r);
        ctx.quadraticCurveTo(width - 0.5, height - cut, width - r - 0.5, height - cut + r);
        ctx.lineTo(width - cut + r, height - r - 0.5);
        ctx.quadraticCurveTo(width - cut, height - 0.5, width - cut - r, height - 0.5);
        ctx.lineTo(r + 0.5, height - 0.5);
        ctx.quadraticCurveTo(0.5, height - 0.5, 0.5, height - r - 0.5);
        ctx.lineTo(0.5, cut + r);
        ctx.quadraticCurveTo(0.5, cut, r + 0.5, cut - r);
        ctx.lineTo(cut - r, r + 0.5);
        ctx.quadraticCurveTo(cut, 0.5, cut + r, 0.5);
        ctx.closePath();
        const paint = ctx.createLinearGradient(0, 0, 0, height);
        paint.addColorStop(0, fill);
        paint.addColorStop(1, lowerFill);
        ctx.fillStyle = paint;
        ctx.fill();
        ctx.strokeStyle = edge;
        ctx.lineWidth = 1;
        ctx.stroke();
    }
}
