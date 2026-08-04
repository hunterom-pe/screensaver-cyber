//
//  CyberpunkSaverView.swift
//  CyberpunkSaver
//
//  Native macOS ScreenSaverView subclass featuring a lightweight, borderless
//  cassette-futurist HUD telemetry overlay without matrix rain or heavy boxes.
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
    private let colorNeonGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let colorNeonCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    private let colorNeonAmber = NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
    private let colorNeonPink = NSColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    private let colorTextMain = NSColor(red: 0.85, green: 0.97, blue: 1.0, alpha: 1.0)
    private let colorTextDim = NSColor(red: 0.85, green: 0.97, blue: 1.0, alpha: 0.55)
    private let colorWidgetBg = NSColor(red: 0.02, green: 0.05, blue: 0.08, alpha: 0.5)

    // MARK: - Pre-Cached Fonts
    private let fontTagBold = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.boldSystemFont(ofSize: 12)
    private let fontTagRegular = NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11)
    private let fontSmall = NSFont(name: "Menlo", size: 10) ?? NSFont.systemFont(ofSize: 10)

    // MARK: - Telemetry & Terminal State
    private var cpuLoad: Int = 34
    private var ramPressure: Int = 62
    private var batReserve: Int = 98

    private var weatherTempStr: String = "--°C"
    private var weatherCondStr: String = "FETCHING METEO..."
    private var weatherAqiStr: String = "AQI 38"
    private var weatherWindStr: String = "12 KM/H"
    private var isOffline: Bool = false

    private var currentLogLine: String = "[14:09:24] KUANG-DENG 0.9 // MATRIX SYNC NOMINAL"
    private let logTemplates = [
        "KUANG-DENG 0.9 // INITIATING NEURAL MATRIX LINK...",
        "BYPASSING CHIBA CITY BACKBONE FIREWALL [GATE 0x8F4A]",
        "ICE DETECTED: BLACK ICE DEFENSE PROTOCOL ACTIVE",
        "DEPLOYING SHIVA DISSOLUTION NODES (0x99F...0x41C)",
        "DECRYPTING SATELLITE TELEMETRY PACKETS... 100% MATCH",
        "CYBER-DEFENSE PULSE NEUTRALIZED. RETAINING ZERO-TRACE.",
        "HOST MEMORY ALLOCATION: 0x00FF8800 [BUFFER STABLE]",
        "OPEN-METEO TELEMETRY SYNCED // PHOENIX NODES RESPONDING",
        "PROMOTION DISPLAY SYNCED // Latency 0.8ms"
    ]

    // MARK: - Assets & Timers
    private var bgImage: NSImage?
    private var renderTimer: Timer?
    private var telemetryTimer: Timer?
    private var weatherTimer: Timer?
    private var terminalTimer: Timer?

    // MARK: - Initializers

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / 30.0 // Smooth 30 FPS timer interval for low CPU load
        setupNativeComponents()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 30.0
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
        self.setNeedsDisplay(self.bounds)
    }

    // MARK: - Lightweight Unified Single-Canvas Drawing Engine

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        // 1. Draw Cyberpunk Balcony Cat Background Image
        if let img = bgImage {
            img.draw(in: bounds, from: .zero, operation: .copy, fraction: 1.0)
        } else {
            colorBgDark.set()
            bounds.fill()
        }

        // 2. Minimalist Floating Corner HUD Elements (No Boxes / Quadrants)
        drawTopLeftHUD(in: ctx, bounds: bounds)
        drawTopRightHUD(in: ctx, bounds: bounds)
        drawBottomLeftHUD(in: ctx, bounds: bounds)
        drawBottomRightHUD(in: ctx, bounds: bounds)

        // 3. Subtle CRT Scanlines
        drawCRTScanlines(in: ctx, bounds: bounds)
    }

    // MARK: - Minimalist Borderless Floating HUD Widgets

    private func drawTopLeftHUD(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let now = Date()
        let fmtTime = DateFormatter()
        fmtTime.dateFormat = "HH:mm:ss"
        let timeStr = fmtTime.string(from: now)

        let fmtDate = DateFormatter()
        fmtDate.dateFormat = "yyyy-MM-dd"
        let dateStr = fmtDate.string(from: now)

        let tagText = "⚡ NOSTROMO // \(timeStr) // \(dateStr)"
        let textRect = CGRect(x: 24, y: bounds.height - 40, width: 340, height: 24)

        // Subtle dark backdrop strip for high legibility
        ctx.setFillColor(colorWidgetBg.cgColor)
        ctx.fill(textRect.insetBy(dx: -6, dy: -2))

        (tagText as NSString).draw(at: CGPoint(x: 24, y: bounds.height - 36), withAttributes: [
            .font: fontTagBold,
            .foregroundColor: colorNeonCyan
        ])
        ctx.restoreGState()
    }

    private func drawTopRightHUD(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let envText: String
        let envColor: NSColor

        if isOffline {
            envText = "⚠️ PHOENIX METEO: SIGNAL LOST // RECONNECTING..."
            envColor = colorNeonPink
        } else {
            envText = "PHOENIX, AZ // \(weatherTempStr)  \(weatherAqiStr)  WIND \(weatherWindStr)"
            envColor = colorNeonAmber
        }

        let textWidth: CGFloat = 380
        let textRect = CGRect(x: bounds.width - textWidth - 24, y: bounds.height - 40, width: textWidth, height: 24)

        ctx.setFillColor(colorWidgetBg.cgColor)
        ctx.fill(textRect.insetBy(dx: -6, dy: -2))

        (envText as NSString).draw(at: CGPoint(x: bounds.width - textWidth - 20, y: bounds.height - 36), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: envColor
        ])
        ctx.restoreGState()
    }

    private func drawBottomLeftHUD(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let termText = "> \(currentLogLine)"
        let textRect = CGRect(x: 24, y: 24, width: 550, height: 24)

        ctx.setFillColor(colorWidgetBg.cgColor)
        ctx.fill(textRect.insetBy(dx: -6, dy: -2))

        (termText as NSString).draw(at: CGPoint(x: 24, y: 28), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorNeonGreen
        ])
        ctx.restoreGState()
    }

    private func drawBottomRightHUD(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
        let sysText = "CPU \(cpuLoad)%  RAM \(ramPressure)%  PWR \(batReserve)%  |  ISS ORBIT 51.64°N"
        let textWidth: CGFloat = 420
        let textRect = CGRect(x: bounds.width - textWidth - 24, y: 24, width: textWidth, height: 24)

        ctx.setFillColor(colorWidgetBg.cgColor)
        ctx.fill(textRect.insetBy(dx: -6, dy: -2))

        (sysText as NSString).draw(at: CGPoint(x: bounds.width - textWidth - 20, y: 28), withAttributes: [
            .font: fontTagRegular,
            .foregroundColor: colorTextMain
        ])
        ctx.restoreGState()
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

    // MARK: - Timers & Background Weather Updates

    private func startTimers() {
        stopTimers()

        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }

        weatherTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.fetchOpenMeteoWeather()
        }

        terminalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
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
        fmt.dateFormat = "HH:mm:ss"
        let timestamp = fmt.string(from: Date())
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

                if let temp = current["temperature_2m"] as? Double {
                    self?.weatherTempStr = "\(Int(round(temp)))°C"
                }
                if let wind = current["wind_speed_10m"] as? Double {
                    self?.weatherWindStr = "\(Int(wind)) KM/H"
                }
                self?.weatherAqiStr = "AQI 38"
                self?.isOffline = false
            }
        }
        task.resume()
    }
}
