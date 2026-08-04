//
//  CyberpunkSaverView.swift
//  CyberpunkSaver
//
//  Native macOS ScreenSaverView subclass featuring ALL Cinematic Cyberpunk Enhancements:
//  Flying Vehicle Light Trails, Breathing Neon Spires, Cybernetic Cat Glow,
//  Holographic Reticles, CRT Glitch Pulses & Option 1 Frosted Glass Badges.
//

import ScreenSaver
import AppKit
import CoreGraphics
import QuartzCore
import Foundation

@objc(CyberpunkSaverView)
public class CyberpunkSaverView: ScreenSaverView {

    // MARK: - Color Palette
    private let colorBgDark = NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
    private let colorBadgeBg = NSColor(red: 0.03, green: 0.06, blue: 0.10, alpha: 0.78)
    private let colorBorderCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.55)
    private let colorBorderGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.55)
    
    private let colorNeonGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let colorNeonCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    private let colorNeonAmber = NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
    private let colorNeonPink = NSColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    private let colorTextMain = NSColor(red: 0.88, green: 0.97, blue: 1.0, alpha: 1.0)
    private let colorTextDim = NSColor(red: 0.88, green: 0.97, blue: 1.0, alpha: 0.6)

    // MARK: - Pre-Cached Fonts
    private let fontClock = NSFont(name: "Menlo-Bold", size: 22) ?? NSFont.boldSystemFont(ofSize: 22)
    private let fontDate = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.boldSystemFont(ofSize: 12)
    private let fontTagBold = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.boldSystemFont(ofSize: 12)
    private let fontTagRegular = NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11)
    private let fontSmall = NSFont(name: "Menlo", size: 10) ?? NSFont.systemFont(ofSize: 10)

    // MARK: - Flying Vehicle Light Trails State
    private struct FlyingVehicle {
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var length: CGFloat
        var isHeadlight: Bool
    }
    private var vehicles: [FlyingVehicle] = []

    // MARK: - Animation & Pulse State
    private var pulseAngle: CGFloat = 0.0
    private var glitchTimer: CGFloat = 0.0
    private var activeGlitchShift: CGFloat = 0.0

    // MARK: - Telemetry & Terminal State
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
        self.animationTimeInterval = 1.0 / 60.0 // Silky 60 FPS animation loop
        setupNativeComponents()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 60.0
        setupNativeComponents()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        initFlyingVehicles()
    }

    // MARK: - Component Setup

    private func setupNativeComponents() {
        let bundle = Bundle(for: type(of: self))
        if let imgURL = bundle.url(forResource: "background", withExtension: "jpg", subdirectory: "WebContent/assets") {
            bgImage = NSImage(contentsOf: imgURL)
        } else if let imgURL = bundle.url(forResource: "background", withExtension: "jpg") {
            bgImage = NSImage(contentsOf: imgURL)
        }

        initFlyingVehicles()
        fetchOpenMeteoWeather()
    }

    private func initFlyingVehicles() {
        let w = max(800, self.bounds.width)
        let h = max(600, self.bounds.height)
        
        vehicles = (0..<7).map { i in
            FlyingVehicle(
                x: CGFloat.random(in: 0...w),
                y: h * CGFloat.random(in: 0.35...0.78),
                speed: CGFloat.random(in: 3.0...7.5) * (i % 2 == 0 ? 1.0 : -1.0),
                length: CGFloat.random(in: 40...90),
                isHeadlight: i % 2 == 0
            )
        }
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
        pulseAngle += 0.04
        glitchTimer += 0.016

        // Update Flying Vehicles
        let w = max(800, self.bounds.width)
        for i in 0..<vehicles.count {
            vehicles[i].x += vehicles[i].speed
            if vehicles[i].speed > 0 && vehicles[i].x > w + 120 {
                vehicles[i].x = -120
            } else if vehicles[i].speed < 0 && vehicles[i].x < -120 {
                vehicles[i].x = w + 120
            }
        }

        // Trigger subtle 0.15s CRT Glitch Twitch every ~18 seconds
        if glitchTimer > 18.0 {
            activeGlitchShift = sin(glitchTimer * 80) * 4.0
            if glitchTimer > 18.2 {
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

        // Apply Glitch Shift if active
        if activeGlitchShift != 0 {
            ctx.saveGState()
            ctx.translateBy(x: activeGlitchShift, y: 0)
        }

        // 1. Draw Cyberpunk Balcony Background Image
        if let img = bgImage {
            img.draw(in: bounds, from: .zero, operation: .copy, fraction: 1.0)
        } else {
            colorBgDark.set()
            bounds.fill()
        }

        // 2. Draw Flying Vehicle Light Trails (Sky Highways)
        drawFlyingVehicles(in: ctx, bounds: bounds)

        // 3. Draw Breathing Skyscraper Beacons & Spire Flares
        drawBreathingBeacons(in: ctx, bounds: bounds)

        // 4. Draw Cybernetic Cat Collar & Eye Glow Accent
        drawCatGlowAccents(in: ctx, bounds: bounds)

        // 5. Draw Holographic Crosshairs & Reticles
        drawHolographicReticles(in: ctx, bounds: bounds)

        // 6. Draw Option 1 High-Contrast Glass Telemetry Badges
        drawTopLeftClockBadge(in: ctx, bounds: bounds)
        drawTopRightWeatherBadge(in: ctx, bounds: bounds)
        drawBottomLeftTerminalBadge(in: ctx, bounds: bounds)
        drawBottomRightMetricsBadge(in: ctx, bounds: bounds)

        // 7. Subtle CRT Scanlines
        drawCRTScanlines(in: ctx, bounds: bounds)

        if activeGlitchShift != 0 {
            ctx.restoreGState()
        }
    }

    // MARK: - 1. Dynamic Flying Vehicle Light Trails

    private func drawFlyingVehicles(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        for vehicle in vehicles {
            let color = vehicle.isHeadlight ? colorNeonCyan : colorNeonPink
            ctx.setStrokeColor(color.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(2.5)

            ctx.move(to: CGPoint(x: vehicle.x, y: vehicle.y))
            let trailX = vehicle.speed > 0 ? vehicle.x - vehicle.length : vehicle.x + vehicle.length
            ctx.addLine(to: CGPoint(x: trailX, y: vehicle.y))
            ctx.strokePath()

            // Glowing Headlight / Taillight Tip
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: vehicle.x - 2, y: vehicle.y - 2, width: 4, height: 4))
        }
        ctx.restoreGState()
    }

    // MARK: - 2. Breathing Neon Skyscraper Beacons

    private func drawBreathingBeacons(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let pulseAlpha = (sin(pulseAngle * 1.5) * 0.35 + 0.65)

        let beaconPoints: [(CGPoint, NSColor)] = [
            (CGPoint(x: bounds.width * 0.22, y: bounds.height * 0.86), colorNeonCyan),
            (CGPoint(x: bounds.width * 0.51, y: bounds.height * 0.82), colorNeonAmber),
            (CGPoint(x: bounds.width * 0.86, y: bounds.height * 0.91), colorNeonPink)
        ]

        for (pt, color) in beaconPoints {
            ctx.setFillColor(color.withAlphaComponent(pulseAlpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))

            // Flare Ring
            ctx.setStrokeColor(color.withAlphaComponent(pulseAlpha * 0.5).cgColor)
            ctx.setLineWidth(1)
            ctx.strokeEllipse(in: CGRect(x: pt.x - 10, y: pt.y - 10, width: 20, height: 20))
        }
        ctx.restoreGState()
    }

    // MARK: - 3. Cybernetic Cat Glow & Ambient Light

    private func drawCatGlowAccents(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let catX = bounds.width * 0.63
        let catY = bounds.height * 0.44
        let pulseAlpha = (sin(pulseAngle * 2.0) * 0.3 + 0.7)

        // Soft ambient neon pool on railing under cat
        ctx.setFillColor(colorNeonCyan.withAlphaComponent(0.18 * pulseAlpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: catX - 25, y: catY - 12, width: 60, height: 16))

        // Cybernetic Collar Neon Glow Band
        ctx.setStrokeColor(colorNeonPink.withAlphaComponent(0.9).cgColor)
        ctx.setLineWidth(2.5)
        ctx.move(to: CGPoint(x: catX - 6, y: catY + 12))
        ctx.addLine(to: CGPoint(x: catX + 12, y: catY + 12))
        ctx.strokePath()

        // Glowing Eye Pulse
        ctx.setFillColor(colorNeonCyan.withAlphaComponent(pulseAlpha).cgColor)
        ctx.fillEllipse(in: CGRect(x: catX - 3, y: catY + 28, width: 3.5, height: 4.5))

        ctx.restoreGState()
    }

    // MARK: - 4. Holographic Reticles & Tactical Crosshairs

    private func drawHolographicReticles(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        ctx.setStrokeColor(colorNeonCyan.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(1.0)

        let crosshairs = [
            CGPoint(x: bounds.width * 0.38, y: bounds.height * 0.55),
            CGPoint(x: bounds.width * 0.72, y: bounds.height * 0.72)
        ]

        for pt in crosshairs {
            let len: CGFloat = 6
            ctx.move(to: CGPoint(x: pt.x - len, y: pt.y))
            ctx.addLine(to: CGPoint(x: pt.x + len, y: pt.y))
            ctx.move(to: CGPoint(x: pt.x, y: pt.y - len))
            ctx.addLine(to: CGPoint(x: pt.x, y: pt.y + len))
            ctx.strokePath()
            ctx.strokeEllipse(in: CGRect(x: pt.x - 8, y: pt.y - 8, width: 16, height: 16))
        }
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

        let badgeRect = CGRect(x: 28, y: bounds.height - 84, width: 280, height: 60)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderGreen)

        (timeStr as NSString).draw(at: CGPoint(x: 42, y: bounds.height - 56), withAttributes: [
            .font: fontClock,
            .foregroundColor: colorNeonGreen
        ])
        (dateStr as NSString).draw(at: CGPoint(x: 42, y: bounds.height - 76), withAttributes: [
            .font: fontDate,
            .foregroundColor: colorTextDim
        ])
        ctx.restoreGState()
    }

    private func drawTopRightWeatherBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeW: CGFloat = 340
        let badgeRect = CGRect(x: bounds.width - badgeW - 28, y: bounds.height - 84, width: badgeW, height: 60)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        if isOffline {
            ("⚠️ PHOENIX METEO TELEMETRY" as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: bounds.height - 54), withAttributes: [
                .font: fontTagBold,
                .foregroundColor: colorNeonPink
            ])
            ("SIGNAL LOST // RECONNECTING..." as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: bounds.height - 74), withAttributes: [
                .font: fontTagRegular,
                .foregroundColor: colorNeonAmber
            ])
        } else {
            let locStr = "PHOENIX, AZ // \(weatherCondStr)"
            let statStr = "\(weatherTempStr)  |  \(weatherAqiStr)  |  \(weatherWindStr)"

            (locStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: bounds.height - 54), withAttributes: [
                .font: fontTagBold,
                .foregroundColor: colorNeonCyan
            ])
            (statStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: bounds.height - 74), withAttributes: [
                .font: fontTagRegular,
                .foregroundColor: colorNeonAmber
            ])
        }
        ctx.restoreGState()
    }

    private func drawBottomLeftTerminalBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeRect = CGRect(x: 28, y: 28, width: 480, height: 56)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        let line1 = "> \(currentLogLine)"
        let line2 = "  \(secondaryLogLine)"

        (line1 as NSString).draw(at: CGPoint(x: 40, y: 60), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorNeonGreen
        ])
        (line2 as NSString).draw(at: CGPoint(x: 40, y: 40), withAttributes: [
            .font: fontSmall,
            .foregroundColor: colorTextDim
        ])
        ctx.restoreGState()
    }

    private func drawBottomRightMetricsBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let badgeW: CGFloat = 430
        let badgeRect = CGRect(x: bounds.width - badgeW - 28, y: 28, width: badgeW, height: 56)
        drawGlassPanel(in: ctx, rect: badgeRect, borderColor: colorBorderCyan)

        let cpuBar = makeProgressBar(percent: cpuLoad)
        let ramBar = makeProgressBar(percent: ramPressure)

        let line1 = "CPU [\(cpuBar)] \(cpuLoad)%   RAM [\(ramBar)] \(ramPressure)%"
        let line2 = "POWER RESERVE \(batReserve)%  |  ISS ORBIT 51.64°N 420.8KM"

        (line1 as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: 60), withAttributes: [
            .font: fontTagBold,
            .foregroundColor: colorTextMain
        ])
        (line2 as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 14, y: 40), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorNeonCyan
        ])
        ctx.restoreGState()
    }

    // MARK: - UI Helpers

    private func drawGlassPanel(in ctx: CGContext, rect: CGRect, borderColor: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        
        colorBadgeBg.set()
        path.fill()

        borderColor.set()
        path.lineWidth = 1.0
        path.stroke()

        // Sci-Fi Corner Wireframe Accent Ticks
        ctx.setStrokeColor(colorNeonCyan.cgColor)
        ctx.setLineWidth(1.5)
        let tick: CGFloat = 5
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
