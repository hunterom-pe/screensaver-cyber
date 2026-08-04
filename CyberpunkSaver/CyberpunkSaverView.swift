//
//  CyberpunkSaverView.swift
//  CyberpunkSaver
//
//  Native macOS ScreenSaverView subclass featuring BOLD, PROMINENT, UNDENIABLY VISIBLE
//  Blade Runner Cyberpunk Effects: Pulsing Neon Halos, Tactical Targeting Frame, Cat Aura,
//  CRT Chromatic Glitch, and Frosted Glass Telemetry Badges.
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
    private let colorBadgeBg = NSColor(red: 0.03, green: 0.07, blue: 0.12, alpha: 0.88)
    private let colorBorderCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.85)
    private let colorBorderGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.85)
    
    private let colorNeonGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let colorNeonCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    private let colorNeonAmber = NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
    private let colorNeonPink = NSColor(red: 1.0, green: 0.0, blue: 0.45, alpha: 1.0)
    private let colorTextMain = NSColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 1.0)
    private let colorTextDim = NSColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 0.65)

    // MARK: - Pre-Cached Fonts
    private let fontClock = NSFont(name: "Menlo-Bold", size: 24) ?? NSFont.boldSystemFont(ofSize: 24)
    private let fontDate = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.boldSystemFont(ofSize: 12)
    private let fontTagBold = NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.boldSystemFont(ofSize: 13)
    private let fontTagRegular = NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)
    private let fontSmall = NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11)

    // MARK: - Animation States
    private var pulseAngle: CGFloat = 0.0
    private var radarAngle: CGFloat = 0.0
    private var glitchTimer: CGFloat = 0.0
    private var activeGlitchShift: CGFloat = 0.0

    // MARK: - Telemetry State
    private var cpuLoad: Int = 34
    private var ramPressure: Int = 62
    private var batReserve: Int = 98

    private var weatherTempStr: String = "38°C / 100°F"
    private var weatherCondStr: String = "CLEAR SOLAR"
    private var weatherAqiStr: String = "AQI 38 (GOOD)"
    private var weatherWindStr: String = "12 KM/H"
    private var isOffline: Bool = false

    private var currentLogLine: String = "KUANG-DENG 0.9 // MATRIX LINK NOMINAL"
    private var secondaryLogLine: String = "SHIVA DECRYPTION NODES SYNCED"
    private let logTemplates = [
        "KUANG-DENG 0.9 // INITIATING NEURAL MATRIX LINK...",
        "BYPASSING CHIBA CITY BACKBONE FIREWALL [GATE 0x8F4A]",
        "ICE DETECTED: BLACK ICE DEFENSE PROTOCOL ACTIVE",
        "DEPLOYING SHIVA DISSOLUTION NODES (0x99F...0x41C)",
        "DECRYPTING SATELLITE TELEMETRY PACKETS... 100% MATCH",
        "CYBER-DEFENSE PULSE NEUTRALIZED. RETAINING ZERO-TRACE.",
        "HOST MEMORY ALLOCATION: 0x00FF8800 [BUFFER STABLE]",
        "OPEN-METEO TELEMETRY SYNCED // PHOENIX NODES RESPONDING",
        "PROMOTION DISPLAY SYNCED // LATENCY 0.8ms"
    ]

    // MARK: - Assets & Timers
    private var bgImage: NSImage?
    private var telemetryTimer: Timer?
    private var weatherTimer: Timer?
    private var terminalTimer: Timer?

    // MARK: - Initializers

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / 60.0 // Smooth 60 FPS animation loop
        setupNativeComponents()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 60.0
        setupNativeComponents()
    }

    // MARK: - Component Setup

    private func setupNativeComponents() {
        let bundle = Bundle(for: type(of: self))
        if let imgURL = bundle.url(forResource: "background", withExtension: "jpg", subdirectory: "WebContent/assets") {
            bgImage = NSImage(contentsOf: imgURL)
        } else if let imgURL = bundle.url(forResource: "background", withExtension: "jpg") {
            bgImage = NSImage(contentsOf: imgURL)
        }

        fetchOpenMeteoWeather()
    }

    // MARK: - Animation Loop

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
        pulseAngle += 0.05
        radarAngle += 0.04
        glitchTimer += 0.016

        // Periodic CRT Chromatic Glitch Flash every 10 seconds
        if glitchTimer > 10.0 {
            activeGlitchShift = sin(glitchTimer * 90) * 8.0
            if glitchTimer > 10.25 {
                glitchTimer = 0.0
                activeGlitchShift = 0.0
            }
        } else {
            activeGlitchShift = 0.0
        }

        self.setNeedsDisplay(self.bounds)
    }

    // MARK: - Unified Single-Canvas Render Engine

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        // Apply Glitch Shift
        if activeGlitchShift != 0 {
            ctx.saveGState()
            ctx.translateBy(x: activeGlitchShift, y: 0)
        }

        // 1. Draw Cyberpunk Balcony Background Image
        if let img = bgImage {
            img.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0)
        } else {
            colorBgDark.set()
            bounds.fill()
        }

        // 2. Draw Prominent Breathing Neon Beacon Halos (Skyscrapers & Skybridges)
        drawBreathingNeonHalos(in: ctx, bounds: bounds)

        // 3. Draw Bold Tactical Reticle & Radar Sweep Frame (Targeting City Skyline)
        drawTacticalTargetingReticle(in: ctx, bounds: bounds)

        // 4. Draw Cat Neon Aura & Cybernetic Eye Pulse
        drawCatNeonAura(in: ctx, bounds: bounds)

        // 5. Draw Option 1 High-Contrast Glass Telemetry Badges
        drawTopLeftClockBadge(in: ctx, bounds: bounds)
        drawTopRightWeatherBadge(in: ctx, bounds: bounds)
        drawBottomLeftTerminalBadge(in: ctx, bounds: bounds)
        drawBottomRightMetricsBadge(in: ctx, bounds: bounds)

        // 6. CRT Scanlines Overlay
        drawCRTScanlines(in: ctx, bounds: bounds)

        if activeGlitchShift != 0 {
            ctx.restoreGState()
        }
    }

    // MARK: - 2. Prominent Breathing Neon Beacon Halos

    private func drawBreathingNeonHalos(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let pulseAlpha = (sin(pulseAngle * 1.8) * 0.35 + 0.65)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let beaconPoints: [(CGPoint, NSColor, CGFloat)] = [
            (CGPoint(x: bounds.width * 0.28, y: bounds.height * 0.82), colorNeonCyan, 60),
            (CGPoint(x: bounds.width * 0.53, y: bounds.height * 0.76), colorNeonAmber, 75),
            (CGPoint(x: bounds.width * 0.82, y: bounds.height * 0.88), colorNeonPink, 65)
        ]

        for (pt, color, radius) in beaconPoints {
            let colors = [
                color.withAlphaComponent(pulseAlpha * 0.85).cgColor,
                color.withAlphaComponent(pulseAlpha * 0.3).cgColor,
                CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0])!
            ] as CFArray

            if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.4, 1.0]) {
                ctx.drawRadialGradient(grad, startCenter: pt, startRadius: 2, endCenter: pt, endRadius: radius, options: [])
            }

            // Solid Beacon Core
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))
        }
        ctx.restoreGState()
    }

    // MARK: - 3. Bold Tactical Reticle & Radar Sweep Frame

    private func drawTacticalTargetingReticle(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let centerPt = CGPoint(x: bounds.width * 0.48, y: bounds.height * 0.58)
        let frameW: CGFloat = 240
        let frameH: CGFloat = 160
        let frameRect = CGRect(x: centerPt.x - frameW/2, y: centerPt.y - frameH/2, width: frameW, height: frameH)

        // Wireframe Corners
        ctx.setStrokeColor(colorNeonCyan.cgColor)
        ctx.setLineWidth(2.5)
        let cornerLen: CGFloat = 20

        // TL Corner
        ctx.move(to: CGPoint(x: frameRect.minX, y: frameRect.maxY - cornerLen))
        ctx.addLine(to: CGPoint(x: frameRect.minX, y: frameRect.maxY))
        ctx.addLine(to: CGPoint(x: frameRect.minX + cornerLen, y: frameRect.maxY))
        ctx.strokePath()

        // TR Corner
        ctx.move(to: CGPoint(x: frameRect.maxX - cornerLen, y: frameRect.maxY))
        ctx.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.maxY))
        ctx.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.maxY - cornerLen))
        ctx.strokePath()

        // BL Corner
        ctx.move(to: CGPoint(x: frameRect.minX, y: frameRect.minY + cornerLen))
        ctx.addLine(to: CGPoint(x: frameRect.minX, y: frameRect.minY))
        ctx.addLine(to: CGPoint(x: frameRect.minX + cornerLen, y: frameRect.minY))
        ctx.strokePath()

        // BR Corner
        ctx.move(to: CGPoint(x: frameRect.maxX - cornerLen, y: frameRect.minY))
        ctx.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.minY))
        ctx.addLine(to: CGPoint(x: frameRect.maxX, y: frameRect.minY + cornerLen))
        ctx.strokePath()

        // Center Crosshair
        ctx.setStrokeColor(colorNeonPink.withAlphaComponent(0.9).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: CGRect(x: centerPt.x - 12, y: centerPt.y - 12, width: 24, height: 24))
        ctx.move(to: CGPoint(x: centerPt.x - 20, y: centerPt.y))
        ctx.addLine(to: CGPoint(x: centerPt.x + 20, y: centerPt.y))
        ctx.move(to: CGPoint(x: centerPt.x, y: centerPt.y - 20))
        ctx.addLine(to: CGPoint(x: centerPt.x, y: centerPt.y + 20))
        ctx.strokePath()

        // Radar Sweep Line
        ctx.setStrokeColor(colorNeonGreen.cgColor)
        ctx.setLineWidth(2.0)
        ctx.move(to: centerPt)
        let sweepX = centerPt.x + cos(radarAngle) * (frameW / 2)
        let sweepY = centerPt.y + sin(radarAngle) * (frameH / 2)
        ctx.addLine(to: CGPoint(x: sweepX, y: sweepY))
        ctx.strokePath()

        // Reticle Tag
        let tagText = "TARGET: CHIBA METROPOLIS // LOCK: 100%"
        (tagText as NSString).draw(at: CGPoint(x: frameRect.minX + 8, y: frameRect.minY - 18), withAttributes: [
            .font: fontSmall,
            .foregroundColor: colorNeonGreen
        ])

        ctx.restoreGState()
    }

    // MARK: - 4. Cat Neon Aura & Eye Pulse

    private func drawCatNeonAura(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let catX = bounds.width * 0.65
        let catY = bounds.height * 0.42
        let pulseAlpha = (sin(pulseAngle * 2.2) * 0.4 + 0.6)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Vibrant Neon Cyan Pool under Cat
        let colors = [
            colorNeonCyan.withAlphaComponent(pulseAlpha * 0.7).cgColor,
            colorNeonCyan.withAlphaComponent(pulseAlpha * 0.25).cgColor,
            CGColor(colorSpace: colorSpace, components: [0, 0, 0, 0])!
        ] as CFArray

        if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.4, 1.0]) {
            ctx.drawRadialGradient(grad, startCenter: CGPoint(x: catX, y: catY), startRadius: 5, endCenter: CGPoint(x: catX, y: catY), endRadius: 80, options: [])
        }

        // Glowing Cat Eyes
        ctx.setFillColor(colorNeonCyan.cgColor)
        ctx.fillEllipse(in: CGRect(x: catX - 4, y: catY + 36, width: 5, height: 6))
        ctx.fillEllipse(in: CGRect(x: catX + 6, y: catY + 36, width: 5, height: 6))

        ctx.restoreGState()
    }

    // MARK: - 5. Option 1 High-Contrast Glass Telemetry Badges

    private func drawTopLeftClockBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let now = Date()

        let fmtTime = DateFormatter()
        fmtTime.dateFormat = "hh:mm:ss a"
        let timeStr = fmtTime.string(from: now)

        let fmtDate = DateFormatter()
        fmtDate.dateFormat = "EEEE, MMMM d, yyyy"
        let dateStr = fmtDate.string(from: now)

        let badgeRect = CGRect(x: 32, y: bounds.height - 92, width: 300, height: 64)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderGreen)

        (timeStr as NSString).draw(at: CGPoint(x: 48, y: bounds.height - 62), withAttributes: [
            .font: fontClock,
            .foregroundColor: colorNeonGreen
        ])
        (dateStr as NSString).draw(at: CGPoint(x: 48, y: bounds.height - 84), withAttributes: [
            .font: fontDate,
            .foregroundColor: colorTextDim
        ])
        ctx.restoreGState()
    }

    private func drawTopRightWeatherBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeW: CGFloat = 360
        let badgeRect = CGRect(x: bounds.width - badgeW - 32, y: bounds.height - 92, width: badgeW, height: 64)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        if isOffline {
            ("⚠️ PHOENIX METEO TELEMETRY" as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 60), withAttributes: [
                .font: fontTagBold,
                .foregroundColor: colorNeonPink
            ])
            ("SIGNAL LOST // RECONNECTING..." as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 82), withAttributes: [
                .font: fontTagRegular,
                .foregroundColor: colorNeonAmber
            ])
        } else {
            let locStr = "PHOENIX, AZ // \(weatherCondStr)"
            let statStr = "\(weatherTempStr)  |  \(weatherAqiStr)  |  \(weatherWindStr)"

            (locStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 60), withAttributes: [
                .font: fontTagBold,
                .foregroundColor: colorNeonCyan
            ])
            (statStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 82), withAttributes: [
                .font: fontTagRegular,
                .foregroundColor: colorNeonAmber
            ])
        }
        ctx.restoreGState()
    }

    private func drawBottomLeftTerminalBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeRect = CGRect(x: 32, y: 32, width: 500, height: 60)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        let line1 = "> \(currentLogLine)"
        let line2 = "  \(secondaryLogLine)"

        (line1 as NSString).draw(at: CGPoint(x: 48, y: 64), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorNeonGreen
        ])
        (line2 as NSString).draw(at: CGPoint(x: 48, y: 44), withAttributes: [
            .font: fontSmall,
            .foregroundColor: colorTextDim
        ])
        ctx.restoreGState()
    }

    private func drawBottomRightMetricsBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeW: CGFloat = 450
        let badgeRect = CGRect(x: bounds.width - badgeW - 32, y: 32, width: badgeW, height: 60)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        let cpuBar = makeProgressBar(percent: cpuLoad)
        let ramBar = makeProgressBar(percent: ramPressure)

        let line1 = "CPU [\(cpuBar)] \(cpuLoad)%   RAM [\(ramBar)] \(ramPressure)%"
        let line2 = "POWER RESERVE \(batReserve)%  |  ISS ORBIT 51.64°N 420.8KM"

        (line1 as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: 64), withAttributes: [
            .font: fontTagBold,
            .foregroundColor: colorTextMain
        ])
        (line2 as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: 44), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorNeonCyan
        ])
        ctx.restoreGState()
    }

    // MARK: - UI Helpers

    private func drawGlassPanel(in ctx: CGContext, rect: CGRect, borderColor: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        
        colorBadgeBg.set()
        path.fill()

        borderColor.set()
        path.lineWidth = 2.0
        path.stroke()

        // Sci-Fi Corner Tick Accents
        ctx.setStrokeColor(colorNeonCyan.cgColor)
        ctx.setLineWidth(2.5)
        let tick: CGFloat = 8
        ctx.move(to: CGPoint(x: rect.minX, y: rect.maxY - tick))
        ctx.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: rect.minX + tick, y: rect.maxY))
        ctx.strokePath()
    }

    private func makeProgressBar(percent: Int) -> String {
        let totalBlocks = 6
        let filled = Int(round(Double(percent) / 100.0 * Double(totalBlocks)))
        let empty = max(0, totalBlocks - filled)
        return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
    }

    private func drawCRTScanlines(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        ctx.setFillColor(NSColor(red: 0, green: 0, blue: 0, alpha: 0.08).cgColor)
        var y: CGFloat = 0
        while y < bounds.height {
            ctx.fill(CGRect(x: 0, y: y, width: bounds.width, height: 2))
            y += 4
        }
        ctx.restoreGState()
    }

    // MARK: - Timers & Background Updates

    private func startTimers() {
        stopTimers()

        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }

        weatherTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.fetchOpenMeteoWeather()
        }

        terminalTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
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
        cpuLoad = Int.random(in: 22...45)
        ramPressure = Int.random(in: 58...70)
    }

    private func appendTerminalLog() {
        let fmt = DateFormatter()
        fmt.dateFormat = "hh:mm:ss a"
        let timestamp = fmt.string(from: Date())
        secondaryLogLine = currentLogLine
        let template = logTemplates[Int.random(in: 0..<logTemplates.count)]
        currentLogLine = "[\(timestamp)] \(template)"
    }

    private func fetchOpenMeteoWeather() {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=33.4484&longitude=-112.0740&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any] else {
                    self?.isOffline = true
                    return
                }

                if let tempC = current["temperature_2m"] as? Double {
                    let tempF = Int(round((tempC * 9.0 / 5.0) + 32.0))
                    let roundedC = Int(round(tempC))
                    self?.weatherTempStr = "\(roundedC)°C / \(tempF)°F"
                }
                if let wind = current["wind_speed_10m"] as? Double {
                    self?.weatherWindStr = "\(Int(wind)) KM/H"
                }
                self?.weatherCondStr = "CLEAR SOLAR"
                self?.weatherAqiStr = "AQI 38 (GOOD)"
                self?.isOffline = false
            }
        }
        task.resume()
    }
}
