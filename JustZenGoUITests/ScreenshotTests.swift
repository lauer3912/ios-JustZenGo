import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        usleep(2000000)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    private func ss(_ name: String) {
        let path = "/tmp/\(name).png"
        let data = app.windows.firstMatch.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: path))
    }

    private func openStatistics() {
        if app.buttons["statistics_btn"].waitForExistence(timeout: 5) {
            app.buttons["statistics_btn"].tap()
        }
        usleep(1500000)
    }

    private func openIntelligence() {
        if app.buttons["intelligence_btn"].waitForExistence(timeout: 5) {
            app.buttons["intelligence_btn"].tap()
        }
        usleep(1500000)
    }

    private func openAchievements() {
        if app.buttons["achievements_btn"].waitForExistence(timeout: 5) {
            app.buttons["achievements_btn"].tap()
        }
        usleep(1500000)
    }

    private func openShop() {
        if app.buttons["shop_btn"].waitForExistence(timeout: 5) {
            app.buttons["shop_btn"].tap()
        }
        usleep(1500000)
    }

    private func openSettings() {
        if app.buttons["settings_btn"].waitForExistence(timeout: 5) {
            app.buttons["settings_btn"].tap()
        }
        usleep(1500000)
    }

    private func dismissSheet() {
        var found = false
        for _ in 0..<30 {
            let allElements = app.otherElements.allElementsBoundByIndex
            for el in allElements {
                if el.exists && el.label == "Done" && el.frame.width > 15 && el.frame.origin.y > 40 && el.frame.origin.y < 250 {
                    el.tap()
                    found = true
                    break
                }
            }
            if found { break }
            app.swipeUp()
            usleep(200000)
        }
    }

    // MARK: - iPhone 6.9" (1320×2868 - iPhone 16 Pro Max)

    func testiPhone_69_01_Home() {
        ss("iPhone_69_portrait_01_Home")
    }

    func testiPhone_69_02_Statistics() {
        openStatistics()
        ss("iPhone_69_portrait_02_Statistics")
    }

    func testiPhone_69_03_Intelligence() {
        openIntelligence()
        ss("iPhone_69_portrait_03_Intelligence")
    }

    func testiPhone_69_04_Achievements() {
        openAchievements()
        ss("iPhone_69_portrait_04_Achievements")
    }

    func testiPhone_69_05_Settings() {
        openSettings()
        ss("iPhone_69_portrait_05_Settings")
    }

    // MARK: - iPhone 6.5" (1284×2778 - iPhone 16 Plus)

    func testiPhone_65_01_Home() {
        ss("iPhone_65_portrait_01_Home")
    }

    func testiPhone_65_02_Statistics() {
        openStatistics()
        ss("iPhone_65_portrait_02_Statistics")
    }

    func testiPhone_65_03_Intelligence() {
        openIntelligence()
        ss("iPhone_65_portrait_03_Intelligence")
    }

    func testiPhone_65_04_Achievements() {
        openAchievements()
        ss("iPhone_65_portrait_04_Achievements")
    }

    func testiPhone_65_05_Settings() {
        openSettings()
        ss("iPhone_65_portrait_05_Settings")
    }

    // MARK: - iPhone 6.3" (1206×2622 - iPhone 16 Pro)

    func testiPhone_63_01_Home() {
        ss("iPhone_63_portrait_01_Home")
    }

    func testiPhone_63_02_Statistics() {
        openStatistics()
        ss("iPhone_63_portrait_02_Statistics")
    }

    func testiPhone_63_03_Intelligence() {
        openIntelligence()
        ss("iPhone_63_portrait_03_Intelligence")
    }

    func testiPhone_63_04_Achievements() {
        openAchievements()
        ss("iPhone_63_portrait_04_Achievements")
    }

    func testiPhone_63_05_Settings() {
        openSettings()
        ss("iPhone_63_portrait_05_Settings")
    }

    // MARK: - iPad 13" (2048×2732 - iPad Pro 13" M4)

    func testiPad_13_01_Home() {
        ss("iPad_13_portrait_01_Home")
    }

    func testiPad_13_02_Statistics() {
        openStatistics()
        ss("iPad_13_portrait_02_Statistics")
    }

    func testiPad_13_03_Intelligence() {
        openIntelligence()
        ss("iPad_13_portrait_03_Intelligence")
    }

    func testiPad_13_04_Achievements() {
        openAchievements()
        ss("iPad_13_portrait_04_Achievements")
    }

    func testiPad_13_05_Settings() {
        openSettings()
        ss("iPad_13_portrait_05_Settings")
    }

    // MARK: - iPad 11" (1668×2388 - iPad Pro 11" M4)

    func testiPad_11_01_Home() {
        ss("iPad_11_portrait_01_Home")
    }

    func testiPad_11_02_Statistics() {
        openStatistics()
        ss("iPad_11_portrait_02_Statistics")
    }

    func testiPad_11_03_Intelligence() {
        openIntelligence()
        ss("iPad_11_portrait_03_Intelligence")
    }

    func testiPad_11_04_Achievements() {
        openAchievements()
        ss("iPad_11_portrait_04_Achievements")
    }

    func testiPad_11_05_Settings() {
        openSettings()
        ss("iPad_11_portrait_05_Settings")
    }
}
