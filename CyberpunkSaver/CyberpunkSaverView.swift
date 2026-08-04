//
//  CyberpunkSaverView.swift
//  CyberpunkSaver
//
//  Native macOS ScreenSaverView subclass with unified single-canvas drawing pipeline
//

import ScreenSaver
import AppKit
import CoreGraphics
import QuartzCore
import Foundation

@objc(CyberpunkSaverView)
public class CyberpunkSaverView: ScreenSaverView {

    // MARK: - Pre-Cached Colors
    private let colorBgDark = NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
    private let colorPanelBg = NSColor(red: 0.03, green: 0.06, blue: 0.09, alpha: 0.78)
    private let colorBorderCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.6)
    private let colorNeonGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let colorNeonCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    private let colorNeonAmber = NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
    private let colorNeonPink = NSColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    private let colorTextMain = NSColor(red: 0.82, green: 0.97, blue: 1.0, alpha: 1.0)
    private let colorTextDim = NSColor(red: 0.82, green: 0.97, blue: 1.0, alpha: 0.5)

    // MARK: - Pre-Cached Fonts & Attribute Dictionaries
    private let fontMatrix = NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.userFixedPitchFont(ofSize: 13)!
    private let fontTitle = NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.boldSystemFont(ofSize: 13)
    private let fontClock = NSFont(name: "Menlo-Bold", size: 18) ?? NSFont.boldSystemFont(ofSize: 18)
    private let fontStatus = NSFont(name: "Menlo", size: 10) ?? NSFont.systemFont(ofSize: 10)
    private let fontHeader = NSFont(name: "Menlo-Bold", size: 11) ?? NSFont.boldSystemFont(ofSize: 11)
    private let fontVal = NSFont(name: "Menlo-Bold", size: 18) ?? NSFont.boldSystemFont(ofSize: 18)
    private let fontBig = NSFont(name: "Menlo-Bold", size: 32) ?? NSFont.boldSystemFont(ofSize: 32)
    private let fontLbl = NSFont(name: "Menlo", size: 10) ?? NSFont.systemFont(ofSize: 10)

    private var attrsMatrixGreen: [NSAttributedString.Key: Any] = [:]
    private var attrsMatrixAmber: [NSAttributedString.Key: Any] = [:]

    // MARK: - Matrix Rain Engine State
    private struct MatrixDrop {
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var isAmber: Bool
        var length: Int
    }
    private var matrixDrops: [MatrixDrop] = []
    private let matrixChars = Array("アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプ01234567890x4F0x9AICE")

    // MARK: - Telemetry & Terminal State
    private var cpuLoad: Int = 34
    private var ramPressure: Int = 62
    private var batReserve: Int = 98
    private var sparklineValues: [CGFloat] = Array(repeating: 0.4, count: 20)

    private var weatherTempStr: String = "--°C"
    private var weatherCondStr: String = "FETCHING METEO TELEMETRY..."
    private var weatherAqiStr: String = "38 (GOOD)"
    private var weatherHumidityStr: String = "42%"
    private var weatherWindStr: String = "12 KM/H"

    private var radarAngle: CGFloat = 0.0
    private var terminalLogs: [String] = []
    private let logTemplates = [
        "KUANG-DENG 0.9 // INITIATING NEURAL MATRIX LINK...",
        "BYPASSING CHIBA CITY BACKBONE FIREWALL [GATE 0x8F4A]",
        "ICE DETECTED: BLACK ICE DEFENSE PROTOCOL ACTIVE",
        "DEPLOYING SHIVA DISSOLUTION NODES (0x99F...0x41C)",
        "DECRYPTING SATELLITE TELEMETRY PACKETS... 100% MATCH",
        "CYBER-DEFENSE PULSE NEUTRALIZED. RETAINING ZERO-TRACE.",
        "HOST MEMORY ALLOCATION: 0x00FF8800 [BUFFER STABLE]",
        "OPEN-METEO TELEMETRY SYNCED // PHOENIX NODES RESPONDING",
        "PROMOTION 120Hz V-SYNC SYNCED // LATENCY 0.8ms"
    ]

    // MARK: - Assets & Timers
    private var bgImage: NSImage?
    private var telemetryTimer: Timer?
    private var weatherTimer: Timer?
    private var terminalTimer: Timer?
    private var catTailAngle: CGFloat = 0.0

    // MARK: - Initializers

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / 120.0
        setupNativeComponents()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 120.0
        setupNativeComponents()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        initMatrixRain()
    }

    // MARK: - Native Component Setup

    private func setupNativeComponents() {
        attrsMatrixGreen = [.font: fontMatrix, .foregroundColor: colorNeonGreen]
        attrsMatrixAmber = [.font: fontMatrix, .foregroundColor: colorNeonAmber]

        // Load background image cleanly into memory
        let bundle = Bundle(for: type(of: self))
        if let imgURL = bundle.url(forResource: "background", withExtension: "jpg", subdirectory: "WebContent/assets") {
            bgImage = NSImage(contentsOf: imgURL)
        } else if let imgURL = bundle.url(forResource: "background", withExtension: "jpg") {
            bgImage = NSImage(contentsOf: imgURL)
        }

        initMatrixRain()
        initTerminalLogs()
        fetchOpenMeteoWeather()
    }

    private func initMatrixRain() {
        let w = max(800, self.bounds.width)
        let colWidth: CGFloat = 22.0
        let numCols = min(45, Int(w / colWidth))
        
        matrixDrops = (0..<numCols).map { col in
            MatrixDrop(
                x: CGFloat(col) * colWidth + 10,
                y: CGFloat.random(in: -600 ... 0),
                speed: CGFloat.random(in: 2.5 ... 6.0),
                isAmber: Double.random(in: 0 ... 1) < 0.15,
                length: Int.random(in: 6 ... 12)
            )
        }
    }

    private func initTerminalLogs() {
        terminalLogs = [
            "[13:50:01.2] KUANG-DENG 0.9 // INITIATING NEURAL MATRIX LINK...",
            "[13:50:02.0] BYPASSING CHIBA CITY BACKBONE FIREWALL [GATE 0x8F4A]",
            "[13:50:02.8] DEPLOYING SHIVA DISSOLUTION NODES (0x99F...0x41C)",
            "[13:50:03.5] CYBER-DEFENSE PULSE NEUTRALIZED. RETAINING ZERO-TRACE.",
            "[13:50:04.1] PROMOTION 120Hz V-SYNC SYNCED // LATENCY 0.8ms"
        ]
    }

    // MARK: - Animation Loop & Render Engine

    public override func startAnimation() {
        super.startAnimation()
        startTimers()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        stopTimers()
    }

    public override func animateOneFrame() {
        super.animateOneFrame()
        updateMatrixRain()
        radarAngle += 0.03
        catTailAngle += 0.04
        self.setNeedsDisplay(self.bounds)
    }

    private func updateMatrixRain() {
        let h = max(600, self.bounds.height)
        for i in 0..<matrixDrops.count {
            matrixDrops[i].y += matrixDrops[i].speed
            if matrixDrops[i].y > h + 150 {
                matrixDrops[i].y = CGFloat.random(in: -250 ... -30)
                matrixDrops[i].speed = CGFloat.random(in: 2.5 ... 6.0)
            }
        }
    }

    // MARK: - Unified Single-Canvas Drawing Engine

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        // 1. Draw Cyberpunk Balcony Background Image or Dark Gradient
        if let img = bgImage {
            img.draw(in: bounds, from: .zero, operation: .copy, fraction: 0.88)
        } else {
            colorBgDark.set()
            bounds.fill()
        }

        // 2. Draw Ambient Cyan/Magenta Cyberpunk Fog Overlay
        drawAmbientGlow(in: ctx, bounds: bounds)

        // 3. Draw 120 FPS Matrix Glyph Rain (25% Opacity)
        drawMatrixRain(in: ctx, bounds: bounds)

        // 4. Draw Balcony Railing & Animated Black Cat
        drawBalconyCat(in: ctx, bounds: bounds)

        // 5. Draw Nostromo HUD Telemetry Layer
        drawHUDHeader(in: ctx, bounds: bounds)
        drawHUDGridPanels(in: ctx, bounds: bounds)
        drawHUDFooter(in: ctx, bounds: bounds)

        // 6. CRT Scanlines
        drawCRTScanlines(in: ctx, bounds: bounds)
    }

    // MARK: - Ambient Glow & Scanlines

    private func drawAmbientGlow(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            NSColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 0.10).cgColor,
            NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.06).cgColor,
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0])!
        ] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.5, 1.0]) {
            ctx.drawRadialGradient(grad, startCenter: CGPoint(x: bounds.width * 0.7, y: bounds.height * 0.7), startRadius: 10, endCenter: CGPoint(x: bounds.width * 0.7, y: bounds.height * 0.7), endRadius: bounds.width * 0.6, options: [])
        }
        ctx.restoreGState()
    }

    private func drawCRTScanlines(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        ctx.setFillColor(NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor)
        var y: CGFloat = 0
        while y < bounds.height {
            ctx.fill(CGRect(x: 0, y: y, width: bounds.width, height: 2))
            y += 4
        }
        ctx.restoreGState()
    }

    // MARK: - Matrix Rain Drawing

    private func drawMatrixRain(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        for drop in matrixDrops {
            let numChars = drop.length
            let attrs = drop.isAmber ? attrsMatrixAmber : attrsMatrixGreen
            
            for j in 0..<numChars {
                let charY = bounds.height - (drop.y - CGFloat(j * 15))
                if charY < -15 || charY > bounds.height + 15 { continue }

                let charIndex = (Int(drop.x + drop.y) + j) % matrixChars.count
                let str = String(matrixChars[charIndex]) as NSString
                str.draw(at: CGPoint(x: drop.x, y: charY), withAttributes: attrs)
            }
        }
        ctx.restoreGState()
    }

    // MARK: - Balcony Railing & Animated Black Cat

    private func drawBalconyCat(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let catX = bounds.width * 0.78
        let catY = bounds.height * 0.18

        ctx.setStrokeColor(colorNeonCyan.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: catX - 80, y: catY))
        ctx.addLine(to: CGPoint(x: catX + 100, y: catY))
        ctx.strokePath()

        ctx.setFillColor(NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0).cgColor)
        ctx.addEllipse(in: CGRect(x: catX, y: catY, width: 36, height: 48))
        ctx.fillPath()

        let headRect = CGRect(x: catX + 6, y: catY + 38, width: 24, height: 24)
        ctx.addEllipse(in: headRect)
        ctx.fillPath()

        let earTwitch = sin(catTailAngle * 0.7) * 3
        let leftEar = CGMutablePath()
        leftEar.move(to: CGPoint(x: catX + 8, y: catY + 56))
        leftEar.addLine(to: CGPoint(x: catX + 12 + earTwitch, y: catY + 70))
        leftEar.addLine(to: CGPoint(x: catX + 17, y: catY + 58))
        leftEar.closeSubpath()
        ctx.addPath(leftEar)
        ctx.fillPath()

        let rightEar = CGMutablePath()
        rightEar.move(to: CGPoint(x: catX + 19, y: catY + 58))
        rightEar.addLine(to: CGPoint(x: catX + 24 - earTwitch, y: catY + 70))
        rightEar.addLine(to: CGPoint(x: catX + 28, y: catY + 56))
        rightEar.closeSubpath()
        ctx.addPath(rightEar)
        ctx.fillPath()

        ctx.setFillColor(colorNeonCyan.cgColor)
        ctx.fillEllipse(in: CGRect(x: catX + 12, y: catY + 48, width: 3, height: 4))
        ctx.fillEllipse(in: CGRect(x: catX + 21, y: catY + 48, width: 3, height: 4))

        ctx.setStrokeColor(NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0).cgColor)
        ctx.setLineWidth(5)
        ctx.setLineCap(.round)

        let tailPath = CGMutablePath()
        let sway = sin(catTailAngle) * 15
        tailPath.move(to: CGPoint(x: catX + 32, y: catY + 12))
        tailPath.addQuadCurve(to: CGPoint(x: catX + 50 + sway, y: catY + 35), control: CGPoint(x: catX + 42 + sway * 0.5, y: catY + 15))
        ctx.addPath(tailPath)
        ctx.strokePath()

        ctx.restoreGState()
    }

    // MARK: - HUD Header & Footer Bar

    private func drawHUDHeader(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let barRect = CGRect(x: 20, y: bounds.height - 60, width: bounds.width - 40, height: 42)

        ctx.setFillColor(colorPanelBg.cgColor)
        ctx.fill(barRect)
        ctx.setStrokeColor(colorBorderCyan.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(barRect)

        ("⚡ NOSTROMO // ICE-BREAKER COMMAND v4.09.2-PROMOTION" as NSString).draw(at: CGPoint(x: 35, y: bounds.height - 48), withAttributes: [.font: fontTitle, .foregroundColor: colorNeonCyan])

        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let timeStr = fmt.string(from: now)
        (timeStr as NSString).draw(at: CGPoint(x: bounds.width / 2 - 40, y: bounds.height - 50), withAttributes: [.font: fontClock, .foregroundColor: colorNeonGreen])

        ("SYSTEM ONLINE // 120 FPS" as NSString).draw(at: CGPoint(x: bounds.width - 230, y: bounds.height - 46), withAttributes: [.font: fontStatus, .foregroundColor: colorNeonGreen])

        ctx.restoreGState()
    }

    private func drawHUDFooter(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let barRect = CGRect(x: 20, y: 16, width: bounds.width - 40, height: 32)
        ctx.setFillColor(colorPanelBg.cgColor)
        ctx.fill(barRect)
        ctx.setStrokeColor(colorBorderCyan.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(barRect)

        ("ENGINE: SWIFT NATIVE METAL 120Hz  |  RENDER: GPU ACCELERATED  |  SECURITY: ICE PROTOCOL NOMINAL" as NSString).draw(at: CGPoint(x: 35, y: 24), withAttributes: [.font: fontLbl, .foregroundColor: colorTextDim])

        ctx.restoreGState()
    }

    // MARK: - HUD Main Grid Panels

    private func drawHUDGridPanels(in ctx: CGContext, bounds: CGRect) {
        let gridY: CGFloat = 64
        let gridH: CGFloat = bounds.height - 140
        let gridW: CGFloat = (bounds.width - 56) / 2

        let rectP1 = CGRect(x: 20, y: gridY + gridH / 2 + 8, width: gridW, height: gridH / 2 - 8)
        drawWireframePanel(in: ctx, rect: rectP1, title: "SYSTEM METRICS // MAINFRAME [SYS-01]")
        drawSystemMetricsContent(in: ctx, rect: rectP1)

        let rectP2 = CGRect(x: bounds.width / 2 + 8, y: gridY + gridH / 2 + 8, width: gridW, height: gridH / 2 - 8)
        drawWireframePanel(in: ctx, rect: rectP2, title: "ENVIRONMENT // PHOENIX, AZ [ENV-02]")
        drawEnvironmentContent(in: ctx, rect: rectP2)

        let rectP3 = CGRect(x: 20, y: gridY, width: gridW, height: gridH / 2 - 8)
        drawWireframePanel(in: ctx, rect: rectP3, title: "SATELLITE TRACKING // ISS ORBIT [SAT-03]")
        drawSatelliteContent(in: ctx, rect: rectP3)

        let rectP4 = CGRect(x: bounds.width / 2 + 8, y: gridY, width: gridW, height: gridH / 2 - 8)
        drawWireframePanel(in: ctx, rect: rectP4, title: "DIAGNOSTIC TERMINAL // NEUROMANCER [TERM-04]")
        drawTerminalContent(in: ctx, rect: rectP4)
    }

    private func drawWireframePanel(in ctx: CGContext, rect: CGRect, title: String) {
        ctx.saveGState()
        ctx.setFillColor(colorPanelBg.cgColor)
        ctx.fill(rect)

        ctx.setStrokeColor(colorBorderCyan.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(rect)

        ctx.setStrokeColor(colorNeonCyan.cgColor)
        ctx.setLineWidth(2)
        let tickLen: CGFloat = 8
        ctx.move(to: CGPoint(x: rect.minX, y: rect.maxY - tickLen))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX + tickLen, y: rect.maxY))
        ctx.strokePath()

        let headerRect = CGRect(x: rect.minX, y: rect.maxY - 24, width: rect.width, height: 24)
        ctx.setFillColor(colorNeonCyan.withAlphaComponent(0.12).cgColor)
        ctx.fill(headerRect)

        (title as NSString).draw(at: CGPoint(x: rect.minX + 10, y: rect.maxY - 18), withAttributes: [.font: fontHeader, .foregroundColor: colorNeonCyan])

        ctx.restoreGState()
    }

    private func drawSystemMetricsContent(in ctx: CGContext, rect: CGRect) {
        ctx.saveGState()

        let g1X = rect.minX + 30
        let gY = rect.maxY - 85
        ("CPU LOAD" as NSString).draw(at: CGPoint(x: g1X, y: gY + 30), withAttributes: [.font: fontLbl, .foregroundColor: colorTextDim])
        ("\(cpuLoad)%" as NSString).draw(at: CGPoint(x: g1X, y: gY), withAttributes: [.font: fontVal, .foregroundColor: colorNeonCyan])

        let g2X = rect.minX + rect.width / 3 + 10
        ("RAM PRESSURE" as NSString).draw(at: CGPoint(x: g2X, y: gY + 30), withAttributes: [.font: fontLbl, .foregroundColor: colorTextDim])
        ("\(ramPressure)%" as NSString).draw(at: CGPoint(x: g2X, y: gY), withAttributes: [.font: fontVal, .foregroundColor: colorNeonAmber])

        let g3X = rect.minX + (rect.width / 3) * 2 + 10
        ("POWER RESERVE" as NSString).draw(at: CGPoint(x: g3X, y: gY + 30), withAttributes: [.font: fontLbl, .foregroundColor: colorTextDim])
        ("\(batReserve)%" as NSString).draw(at: CGPoint(x: g3X, y: gY), withAttributes: [.font: fontVal, .foregroundColor: colorNeonGreen])

        let sparkRect = CGRect(x: rect.minX + 20, y: rect.minY + 20, width: rect.width - 40, height: 35)
        ctx.setFillColor(NSColor.black.withAlphaComponent(0.4).cgColor)
        ctx.fill(sparkRect)

        let colW = sparkRect.width / CGFloat(sparklineValues.count)
        ctx.setFillColor(colorNeonCyan.withAlphaComponent(0.7).cgColor)
        for (idx, val) in sparklineValues.enumerated() {
            let barH = sparkRect.height * val
            ctx.fill(CGRect(x: sparkRect.minX + CGFloat(idx) * colW, y: sparkRect.minY, width: colW - 2, height: barH))
        }

        ctx.restoreGState()
    }

    private func drawEnvironmentContent(in ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        (weatherTempStr as NSString).draw(at: CGPoint(x: rect.minX + 20, y: rect.maxY - 75), withAttributes: [.font: fontBig, .foregroundColor: colorNeonAmber])
        (weatherCondStr as NSString).draw(at: CGPoint(x: rect.minX + 170, y: rect.maxY - 55), withAttributes: [.font: fontLbl, .foregroundColor: colorTextMain])
        ("LAT 33.4484° N // LON 112.0740° W" as NSString).draw(at: CGPoint(x: rect.minX + 170, y: rect.maxY - 72), withAttributes: [.font: fontLbl, .foregroundColor: colorTextDim])

        let statStr = "AQI: \(weatherAqiStr)  |  HUMIDITY: \(weatherHumidityStr)  |  WIND: \(weatherWindStr)"
        (statStr as NSString).draw(at: CGPoint(x: rect.minX + 20, y: rect.minY + 25), withAttributes: [.font: fontLbl, .foregroundColor: colorNeonGreen])
        ctx.restoreGState()
    }

    private func drawSatelliteContent(in ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        let radarCenter = CGPoint(x: rect.minX + rect.width / 2, y: rect.minY + rect.height / 2 - 10)
        let radarRadius: CGFloat = min(rect.width, rect.height) / 2 - 30

        ctx.setStrokeColor(colorNeonCyan.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: CGRect(x: radarCenter.x - radarRadius, y: radarCenter.y - radarRadius, width: radarRadius * 2, height: radarRadius * 2))
        ctx.strokeEllipse(in: CGRect(x: radarCenter.x - radarRadius * 0.6, y: radarCenter.y - radarRadius * 0.6, width: radarRadius * 1.2, height: radarRadius * 1.2))

        ctx.setStrokeColor(colorNeonGreen.cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: radarCenter)
        let sweepX = radarCenter.x + cos(radarAngle) * radarRadius
        let sweepY = radarCenter.y + sin(radarAngle) * radarRadius
        ctx.addLine(to: CGPoint(x: sweepX, y: sweepY))
        ctx.strokePath()

        ("TARGET: ISS (NORAD #25544)  ORBIT: 51.64° N  ALT: 420.8 KM" as NSString).draw(at: CGPoint(x: rect.minX + 20, y: rect.minY + 15), withAttributes: [.font: fontLbl, .foregroundColor: colorNeonGreen])

        ctx.restoreGState()
    }

    private func drawTerminalContent(in ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        var logY = rect.maxY - 45

        for log in terminalLogs.suffix(8) {
            if logY < rect.minY + 15 { break }
            (log as NSString).draw(at: CGPoint(x: rect.minX + 15, y: logY), withAttributes: [.font: fontLbl, .foregroundColor: colorNeonGreen])
            logY -= 16
        }
        ctx.restoreGState()
    }

    // MARK: - Background Timers & Open-Meteo REST API

    private func startTimers() {
        stopTimers()

        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }

        weatherTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.fetchOpenMeteoWeather()
        }

        terminalTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { [weak self] _ in
            self?.appendTerminalLog()
        }
    }

    private func stopTimers() {
        telemetryTimer?.invalidate()
        telemetryTimer = nil
        weatherTimer?.invalidate()
        weatherTimer = nil
        terminalTimer?.invalidate()
        terminalTimer = nil
    }

    private func updateSystemMetrics() {
        cpuLoad = Int.random(in: 22...48)
        ramPressure = Int.random(in: 58...72)
        sparklineValues.removeFirst()
        sparklineValues.append(CGFloat.random(in: 0.15...0.85))
    }

    private func appendTerminalLog() {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss.S"
        let timestamp = fmt.string(from: Date())
        let template = logTemplates[Int.random(in: 0..<logTemplates.count)]
        terminalLogs.append("[\(timestamp)] \(template)")
        if terminalLogs.count > 30 { terminalLogs.removeFirst() }
    }

    private func fetchOpenMeteoWeather() {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=33.4484&longitude=-112.0740&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any] else {
                    return
                }

                if let temp = current["temperature_2m"] as? Double {
                    self?.weatherTempStr = "\(Int(round(temp)))°C"
                }
                if let hum = current["relative_humidity_2m"] as? Double {
                    self?.weatherHumidityStr = "\(Int(hum))%"
                }
                if let wind = current["wind_speed_10m"] as? Double {
                    self?.weatherWindStr = "\(Int(wind)) KM/H"
                }
                self?.weatherCondStr = "ATMOSPHERIC CLEAR // SOLAR OPTICAL"
            }
        }
        task.resume()
    }
}
