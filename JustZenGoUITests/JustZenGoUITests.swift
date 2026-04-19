import XCTest

final class JustZenGoUITests: XCTestCase {

    private var app: XCUIApplication!
    private let screenshotDir = "/tmp/JustZenGoScreenshots"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        try? FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)
        app.launchArguments = []
        app.launch()
        Thread.sleep(forTimeInterval: 4.0)
    }

    private func ss(_ name: String) {
        let data = app.windows.firstMatch.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(screenshotDir)/\(name).png"))
        print("Saved: \(name) (\(data.count) bytes, window=\(app.windows.firstMatch.frame))")
    }

    // Dismiss sheet via Done button (most reliable), fallback to swipeDown
    private func dismissSheet() {
        var found = false
        for i in 0..<30 {
            let allElements = app.otherElements.allElementsBoundByIndex
            for el in allElements {
                if el.exists && el.label == "Done" && el.frame.width > 15 && el.frame.origin.y > 40 && el.frame.origin.y < 250 {
                    el.tap()
                    found = true
                    break
                }
            }
            if found { break }
            Thread.sleep(forTimeInterval: 0.2)
        }
        if !found {
            app.windows.firstMatch.swipeDown()
            print("dismissSheet: used swipeDown fallback")
        }
        Thread.sleep(forTimeInterval: 1.5)
    }

    // Rotate simulator display via xcrun simctl
    private func simRotate(angle: Int) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl", "rotateui", "booted", "--angle=\(angle)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        try? task.run()
        task.waitUntilExit()
        print("simRotate angle=\(angle) exitCode=\(task.terminationStatus)")
    }

    // ─────────────────────────────────────────────────────
    // iPhone 6.9" — portrait 1320×2868
    // ─────────────────────────────────────────────────────
    func testScreenshot_iPhone_69_portrait() {
        print("=== iPhone 6.9\" portrait (1320×2868) ===")
        ss("iPhone_69_portrait_01_Home.png")
        Thread.sleep(forTimeInterval: 1.0)

        if app.buttons["statistics_btn"].waitForExistence(timeout: 5) {
            app.buttons["statistics_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_portrait_02_Statistics.png")
            dismissSheet()
        }

        if app.buttons["intelligence_btn"].waitForExistence(timeout: 5) {
            app.buttons["intelligence_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_portrait_03_Intelligence.png")
            dismissSheet()
        }

        if app.buttons["achievements_btn"].waitForExistence(timeout: 5) {
            app.buttons["achievements_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_portrait_04_Achievements.png")
            dismissSheet()
        }

        if app.buttons["shop_btn"].waitForExistence(timeout: 5) {
            app.buttons["shop_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_portrait_05_Shop.png")
            dismissSheet()
        }
    }

    // ─────────────────────────────────────────────────────
    // iPhone 6.9" — landscape 2868×1320
    // ─────────────────────────────────────────────────────
    func testScreenshot_iPhone_69_landscape() {
        print("=== iPhone 6.9\" landscape (2868×1320) ===")
        simRotate(angle: 90)
        Thread.sleep(forTimeInterval: 2.0)

        ss("iPhone_69_landscape_01_Home.png")
        Thread.sleep(forTimeInterval: 1.0)

        if app.buttons["statistics_btn"].waitForExistence(timeout: 5) {
            app.buttons["statistics_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_landscape_02_Statistics.png")
            dismissSheet()
        }

        if app.buttons["intelligence_btn"].waitForExistence(timeout: 5) {
            app.buttons["intelligence_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_landscape_03_Intelligence.png")
            dismissSheet()
        }

        if app.buttons["achievements_btn"].waitForExistence(timeout: 5) {
            app.buttons["achievements_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPhone_69_landscape_04_Achievements.png")
            dismissSheet()
        }

        simRotate(angle: 0)
        Thread.sleep(forTimeInterval: 1.0)
    }

    // ─────────────────────────────────────────────────────
    // iPad 12.9" — portrait 2064×2752
    // ─────────────────────────────────────────────────────
    func testScreenshot_iPad_129_portrait() {
        print("=== iPad 12.9\" portrait (2064×2752) ===")
        ss("iPad_129_portrait_01_Home.png")
        Thread.sleep(forTimeInterval: 1.0)

        if app.buttons["statistics_btn"].waitForExistence(timeout: 5) {
            app.buttons["statistics_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_portrait_02_Statistics.png")
            dismissSheet()
        }

        if app.buttons["intelligence_btn"].waitForExistence(timeout: 5) {
            app.buttons["intelligence_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_portrait_03_Intelligence.png")
            dismissSheet()
        }

        if app.buttons["achievements_btn"].waitForExistence(timeout: 5) {
            app.buttons["achievements_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_portrait_04_Achievements.png")
            dismissSheet()
        }

        if app.buttons["shop_btn"].waitForExistence(timeout: 5) {
            app.buttons["shop_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_portrait_05_Shop.png")
            dismissSheet()
        }
    }

    // ─────────────────────────────────────────────────────
    // iPad 12.9" — landscape 2752×2064
    // ─────────────────────────────────────────────────────
    func testScreenshot_iPad_129_landscape() {
        print("=== iPad 12.9\" landscape (2752×2064) ===")
        simRotate(angle: 90)
        Thread.sleep(forTimeInterval: 2.0)

        ss("iPad_129_landscape_01_Home.png")
        Thread.sleep(forTimeInterval: 1.0)

        if app.buttons["statistics_btn"].waitForExistence(timeout: 5) {
            app.buttons["statistics_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_landscape_02_Statistics.png")
            dismissSheet()
        }

        if app.buttons["intelligence_btn"].waitForExistence(timeout: 5) {
            app.buttons["intelligence_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_landscape_03_Intelligence.png")
            dismissSheet()
        }

        if app.buttons["achievements_btn"].waitForExistence(timeout: 5) {
            app.buttons["achievements_btn"].tap()
            Thread.sleep(forTimeInterval: 3.0)
            ss("iPad_129_landscape_04_Achievements.png")
            dismissSheet()
        }

        simRotate(angle: 0)
        Thread.sleep(forTimeInterval: 1.0)
    }
}
