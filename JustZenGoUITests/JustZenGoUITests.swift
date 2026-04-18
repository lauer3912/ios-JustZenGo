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
        sleep(3)
    }
    
    private func ss(_ name: String) {
        let window = app.windows.firstMatch
        let data = window.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(screenshotDir)/\(name).png"))
        print("Saved: \(name) (\(data.count) bytes)")
    }
    
    private func dismiss() {
        // Try Done button first
        let done = app.buttons["Done"]
        if done.exists {
            print("Tapping Done button to dismiss")
            done.tap()
        } else {
            // Fallback to swipe
            print("No Done button, swiping down")
            app.windows.firstMatch.swipeDown()
        }
        Thread.sleep(forTimeInterval: 2)
    }
    
    func testScreenshots() {
        ss("Screen1_Home")
        
        // Statistics
        app.buttons["statistics_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen2_Statistics")
        dismiss()
        ss("Screen1_Home_after_close")
        
        // Intelligence
        app.buttons["intelligence_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen3_Intelligence")
        dismiss()
        
        // Settings (coordinate tap since x > window width)
        let gear = app.buttons["settings_btn"]
        if gear.exists {
            let frame = gear.frame
            let window = app.windows.firstMatch
            let coord = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY))
            coord.tap()
            Thread.sleep(forTimeInterval: 2)
            ss("Screen4_Settings")
            dismiss()
        }
        
        // Achievements
        app.buttons["achievements_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen5_Achievements")
        dismiss()
        
        // Shop
        app.buttons["shop_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen6_Shop")
        dismiss()
        
        // Profile
        app.buttons["profile_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen7_Profile")
        dismiss()
        
        // Projects
        app.buttons["project_btn"].tap()
        Thread.sleep(forTimeInterval: 2)
        ss("Screen8_Projects")
        dismiss()
        
        print("ALL DONE")
    }
}
