//
//  CyberpunkSaverView.swift
//  CyberpunkSaver
//
//  Native macOS ScreenSaverView subclass with AVFoundation MP4 Looping Video Support.
//  Renders hardware-accelerated looping video (background.mp4) or background.jpg fallback,
//  with Option 1 Frosted Glass Telemetry Badges (12-Hour Clock, Phoenix Weather, Real CPU/RAM).
//

import ScreenSaver
import AppKit
import CoreGraphics
import QuartzCore
import AVFoundation
import IOKit.ps

// MARK: - HUD Overlay View (Renders Badges over Video)

private class HUDOverlayView: NSView {
    
    // Telemetry Data (Passed from Parent)
    var timeStr: String = ""
    var dateStr: String = ""
    var weatherLocStr: String = "PHOENIX, AZ // CLEAR SOLAR"
    var weatherStatStr: String = "38°C / 100°F  |  AQI 38 (GOOD)  |  12 KM/H"
    var isOffline: Bool = false
    var currentLogLine: String = "KUANG-DENG 0.9 // MATRIX LINK NOMINAL"
    var secondaryLogLine: String = "SHIVA DECRYPTION NODES SYNCED"
    var cpuLoad: Int = 0
    var ramPressure: Int = 0
    var batReserve: Int = 100
    var isCharging: Bool = true

    // Pre-Cached Colors
    private let colorBadgeBg = NSColor(red: 0.02, green: 0.05, blue: 0.09, alpha: 0.88)
    private let colorBorderCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.7)
    private let colorBorderGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.7)
    private let colorNeonGreen = NSColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
    private let colorNeonCyan = NSColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1.0)
    private let colorNeonAmber = NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1.0)
    private let colorNeonPink = NSColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0)
    private let colorTextMain = NSColor(red: 0.88, green: 0.97, blue: 1.0, alpha: 1.0)
    private let colorTextDim = NSColor(red: 0.88, green: 0.97, blue: 1.0, alpha: 0.6)

    // Pre-Cached Fonts
    private let fontClock = NSFont(name: "Menlo-Bold", size: 24) ?? NSFont.boldSystemFont(ofSize: 24)
    private let fontDate = NSFont(name: "Menlo-Bold", size: 12) ?? NSFont.boldSystemFont(ofSize: 12)
    private let fontTagBold = NSFont(name: "Menlo-Bold", size: 13) ?? NSFont.boldSystemFont(ofSize: 13)
    private let fontTagRegular = NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12)
    private let fontSmall = NSFont(name: "Menlo", size: 11) ?? NSFont.systemFont(ofSize: 11)

    override var isOpaque: Bool { return false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        drawTopLeftClockBadge(in: ctx, bounds: bounds)
        drawTopRightWeatherBadge(in: ctx, bounds: bounds)
        drawBottomLeftTerminalBadge(in: ctx, bounds: bounds)
        drawBottomRightMetricsBadge(in: ctx, bounds: bounds)
        drawCRTScanlines(in: ctx, bounds: bounds)
    }

    private func drawTopLeftClockBadge(in ctx: CGContext, bounds: CGRect) {
        ctx.saveGState()
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
            (weatherLocStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 60), withAttributes: [
                .font: fontTagBold,
                .foregroundColor: colorNeonCyan
            ])
            (weatherStatStr as NSString).draw(at: CGPoint(x: bounds.width - badgeW - 16, y: bounds.height - 82), withAttributes: [
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
        let powerTag = isCharging ? "AC PWR \(batReserve)%" : "BAT \(batReserve)%"

        let line1 = "REAL CPU [\(cpuBar)] \(cpuLoad)%   RAM [\(ramBar)] \(ramPressure)%"
        let line2 = "\(powerTag)  |  ISS ORBIT 51.64°N 420.8KM"

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

    private func drawGlassPanel(in ctx: CGContext, rect: CGRect, borderColor: NSColor) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        colorBadgeBg.set()
        path.fill()

        borderColor.set()
        path.lineWidth = 1.5
        path.stroke()

        ctx.setStrokeColor(colorNeonCyan.cgColor)
        ctx.setLineWidth(2.0)
        let tick: CGFloat = 6
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
}

// MARK: - Primary CyberpunkSaverView Class

@objc(CyberpunkSaverView)
public class CyberpunkSaverView: ScreenSaverView {

    private var hudView: HUDOverlayView?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var imageLayer: CALayer?

    private var previousCpuLoadInfo: (totalInUse: UInt64, totalTicks: UInt64)?
    private var telemetryTimer: Timer?
    private var weatherTimer: Timer?
    private var terminalTimer: Timer?

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

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 / 30.0
        setupMediaAndHUD()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0 / 30.0
        setupMediaAndHUD()
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        playerLayer?.frame = self.bounds
        imageLayer?.frame = self.bounds
        hudView?.frame = self.bounds
    }

    private func setupMediaAndHUD() {
        self.wantsLayer = true
        guard let mainLayer = self.layer else { return }

        let bundle = Bundle(for: type(of: self))
        let videoURL = bundle.url(forResource: "background", withExtension: "mp4", subdirectory: "WebContent/assets")
                     ?? bundle.url(forResource: "background", withExtension: "mp4")

        if let url = videoURL {
            let item = AVPlayerItem(url: url)
            let qPlayer = AVQueuePlayer(playerItem: item)
            playerLooper = AVPlayerLooper(player: qPlayer, templateItem: item)
            
            let pLayer = AVPlayerLayer(player: qPlayer)
            pLayer.videoGravity = .resizeAspectFill
            pLayer.frame = self.bounds
            pLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

            mainLayer.addSublayer(pLayer)
            self.playerLayer = pLayer
            self.player = qPlayer
            qPlayer.play()
        } else {
            // Static Image Fallback
            var bgImg: NSImage?
            if let imgURL = bundle.url(forResource: "background", withExtension: "jpg", subdirectory: "WebContent/assets") {
                bgImg = NSImage(contentsOf: imgURL)
            } else if let imgURL = bundle.url(forResource: "background", withExtension: "jpg") {
                bgImg = NSImage(contentsOf: imgURL)
            }

            if let img = bgImg {
                let imgL = CALayer()
                imgL.frame = self.bounds
                imgL.contents = img.layerContents(forContentsScale: self.window?.backingScaleFactor ?? 2.0)
                imgL.contentsGravity = .resizeAspectFill
                imgL.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
                mainLayer.addSublayer(imgL)
                self.imageLayer = imgL
            }
        }

        // Add HUD Overlay View
        let hud = HUDOverlayView(frame: self.bounds)
        hud.autoresizingMask = [.width, .height]
        self.addSubview(hud)
        self.hudView = hud

        updateRealSystemMetrics()
        fetchOpenMeteoWeather()
    }

    public override func startAnimation() {
        super.startAnimation()
        player?.play()
        startTimers()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
        stopTimers()
    }

    public override func animateOneFrame() {
        super.animateOneFrame()
        updateClockStrings()
        hudView?.needsDisplay = true
    }

    private func updateClockStrings() {
        let now = Date()
        let fmtTime = DateFormatter()
        fmtTime.dateFormat = "hh:mm:ss a"
        hudView?.timeStr = fmtTime.string(from: now)

        let fmtDate = DateFormatter()
        fmtDate.dateFormat = "EEEE, MMMM d, yyyy"
        hudView?.dateStr = fmtDate.string(from: now)
    }

    // MARK: - Real Host Kernel Telemetry Queries

    private func updateRealSystemMetrics() {
        hudView?.cpuLoad = fetchRealCPULoad()
        hudView?.ramPressure = fetchRealRAMPressure()
        let batInfo = fetchRealBatteryInfo()
        hudView?.batReserve = batInfo.percent
        hudView?.isCharging = batInfo.isCharging
    }

    private func fetchRealCPULoad() -> Int {
        var processorInfo: processor_info_array_t?
        var numProcessorInfo: mach_msg_type_number_t = 0
        var numProcessors: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numProcessors,
            &processorInfo,
            &numProcessorInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = processorInfo else {
            return 28
        }

        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0

        let count = Int(numProcessorInfo)
        for i in 0..<Int(numProcessors) {
            let base = i * Int(CPU_STATE_MAX)
            if base + Int(CPU_STATE_NICE) < count {
                totalUser += UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
                totalSystem += UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
                totalIdle += UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
                totalNice += UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
            }
        }

        let totalInUse = totalUser + totalSystem + totalNice
        let totalTicks = totalInUse + totalIdle

        var usagePercent: Double = 0.0
        if let prev = previousCpuLoadInfo {
            let diffInUse = Double(totalInUse > prev.totalInUse ? totalInUse - prev.totalInUse : 0)
            let diffTotal = Double(totalTicks > prev.totalTicks ? totalTicks - prev.totalTicks : 1)
            usagePercent = (diffInUse / diffTotal) * 100.0
        } else {
            usagePercent = (Double(totalInUse) / Double(max(1, totalTicks))) * 100.0
        }

        previousCpuLoadInfo = (totalInUse: totalInUse, totalTicks: totalTicks)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numProcessorInfo) * MemoryLayout<integer_t>.stride))

        return max(1, min(100, Int(round(usagePercent))))
    }

    private func fetchRealRAMPressure() -> Int {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
            }
        }

        guard kerr == KERN_SUCCESS else { return 62 }

        let active = Double(stats.active_count)
        let wire = Double(stats.wire_count)
        let compressed = Double(stats.compressor_page_count)
        let free = Double(stats.free_count)
        let inactive = Double(stats.inactive_count)

        let totalPages = active + wire + compressed + free + inactive
        if totalPages > 0 {
            let usedPages = active + wire + compressed
            let percentage = (usedPages / totalPages) * 100.0
            return max(1, min(100, Int(round(percentage))))
        }
        return 62
    }

    private func fetchRealBatteryInfo() -> (percent: Int, isCharging: Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return (100, true)
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 100
                let state = description[kIOPSPowerSourceStateKey] as? String ?? ""
                let isCharging = (state == kIOPSACPowerValue) || ((description[kIOPSIsChargingKey] as? Bool) ?? false)
                return (capacity, isCharging)
            }
        }
        return (100, true)
    }

    // MARK: - Timers & Background Updates

    private func startTimers() {
        stopTimers()

        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateRealSystemMetrics()
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

    private func appendTerminalLog() {
        let fmt = DateFormatter()
        fmt.dateFormat = "hh:mm:ss a"
        let timestamp = fmt.string(from: Date())
        hudView?.secondaryLogLine = hudView?.currentLogLine ?? ""
        let template = logTemplates[Int.random(in: 0..<logTemplates.count)]
        hudView?.currentLogLine = "[\(timestamp)] \(template)"
    }

    private func fetchOpenMeteoWeather() {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=33.4484&longitude=-112.0740&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any] else {
                    self?.hudView?.isOffline = true
                    return
                }

                if let tempC = current["temperature_2m"] as? Double {
                    let tempF = Int(round((tempC * 9.0 / 5.0) + 32.0))
                    let roundedC = Int(round(tempC))
                    self?.hudView?.weatherStatStr = "\(roundedC)°C / \(tempF)°F  |  AQI 38 (GOOD)"
                }
                if let wind = current["wind_speed_10m"] as? Double {
                    self?.hudView?.weatherStatStr += "  |  \(Int(wind)) KM/H"
                }
                self?.hudView?.weatherLocStr = "PHOENIX, AZ // CLEAR SOLAR"
                self?.hudView?.isOffline = false
            }
        }
        task.resume()
    }
}
