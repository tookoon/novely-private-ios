import XCTest

final class NovelyPrivateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAllScreensForVisualReview() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        // 1. Main Bookshelf Screen (Gelesen)
        sleep(2)
        attachScreenshot(name: "01_Bookshelf_Gelesen")

        // 2. Open Shelf Customizer
        if app.buttons["customizeShelfButton"].waitForExistence(timeout: 3) {
            app.buttons["customizeShelfButton"].tap()
            sleep(1)
            attachScreenshot(name: "02_Shelf_Customizer")
            if app.buttons["Fertig"].exists {
                app.buttons["Fertig"].tap()
                sleep(1)
            }
        }

        // 3. Open First Book Detail (3D Book Viewer)
        let firstBookText = app.staticTexts["Iron Flame"]
        if firstBookText.waitForExistence(timeout: 3) {
            firstBookText.tap()
            sleep(1)
            attachScreenshot(name: "03_BookDetail_3D")
            if app.buttons["Schließen"].exists {
                app.buttons["Schließen"].tap()
                sleep(1)
            }
        }

        // 4. Progress & Quotes Tab ("Aktuell")
        let progressTab = app.tabBars.buttons["Aktuell"]
        if progressTab.waitForExistence(timeout: 3) {
            progressTab.tap()
            sleep(1)
            attachScreenshot(name: "04_Progress_And_Quotes")
        }

        // 5. Cozy Reading Room ("Lesezeit")
        let readingTab = app.tabBars.buttons["Lesezeit"]
        if readingTab.waitForExistence(timeout: 3) {
            readingTab.tap()
            sleep(2)
            attachScreenshot(name: "05_ReadingRoom_Winter")

            let kaminRoomButton = app.buttons["roomTheme_Kamin"]
            if kaminRoomButton.waitForExistence(timeout: 3) {
                kaminRoomButton.tap()
                sleep(1)
                attachScreenshot(name: "06_ReadingRoom_Fireplace")
            }
        }

        // 6. Statistics, Streak & Reading Calendar ("Statistik")
        let statsTab = app.tabBars.buttons["Statistik"]
        if statsTab.waitForExistence(timeout: 3) {
            statsTab.tap()
            sleep(1)
            attachScreenshot(name: "07_Stats_Streak_Calendar")

            app.swipeUp()
            sleep(1)
            attachScreenshot(name: "08_Stats_Calendar_Value")
        }

        // 7. Discover, Import & Settings ("Mehr")
        let moreTab = app.tabBars.buttons["Mehr"]
        if moreTab.waitForExistence(timeout: 3) {
            moreTab.tap()
            sleep(1)
            attachScreenshot(name: "09_More_And_Import")
        }
    }

    private func attachScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
