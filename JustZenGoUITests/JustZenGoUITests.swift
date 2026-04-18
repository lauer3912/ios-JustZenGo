import XCTest

final class JustZenGoUITests: XCTestCase {
    
    private var app: XCUIApplication!
    private let screenshotDir = "/tmp/JustZenGoScreenshotsFinal"
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        try? FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)
        app.launchArguments = []
        app.launch()
        sleep(3)
    }
    
    private func ss(_ name: String) {
        let window = app.windows.firstMatch
        let data = window.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(screenshotDir)/\(name).png"))
        print("Saved: \(name) (\(data.count) bytes)")
    }
    
    // Dismiss: wait for Done in toolbar, tap it, wait for it to disappear
    private func dismissSheet() {
        // Wait for Done in toolbar (y: 50-200)
        var doneFrame: CGRect?
        for _ in 0..<60 {
            let others = app.otherElements.allElementsBoundByIndex
            for el in others {
                if el.label == "Done" && el.frame.width > 15 && el.frame.origin.y > 50 && el.frame.origin.y < 200 {
                    doneFrame = el.frame
                    break
                }
            }
            if doneFrame != nil { break }
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        if let frame = doneFrame {
            let window = app.windows.firstMatch
            let coord = window.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.midX, dy: frame.midY))
            coord.tap()
            print("Tapped Done at (\(String(format: "%.0f", frame.origin.x)), \(String(format: "%.0f", frame.origin.y)))")
        } else {
            app.windows.firstMatch.swipeDown()
            print("Swipe down (Done not found)")
        }
        
        // Wait for Done to be gone
        Thread.sleep(forTimeInterval: 1.5)
    }
    
    func testScreenshots() {
        ss("01_Home")
        
        // Statistics
        app.buttons["statistics_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("02_Statistics")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Intelligence
        app.buttons["intelligence_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("03_Intelligence")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Settings
        app.buttons["settings_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("04_Settings")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Achievements
        app.buttons["achievements_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("05_Achievements")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Shop
        app.buttons["shop_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("06_Shop")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Profile
        app.buttons["profile_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("07_Profile")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Projects
        app.buttons["project_btn"].tap()
        Thread.sleep(forTimeInterval: 3.0)
        ss("08_Projects")
        dismissSheet()
        
        print("ALL DONE")
    }
}
