import XCTest

final class NovelyPrivateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAllV2ScreensForVisualReview() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        // Wait for concurrent Apple Books + Google Books real cover hydration on launch
        sleep(8)
        attachScreenshot(name: "01_Bookshelf_WarmWood_Cat_Plant")

        // 2. Edit Mode on Shelf (showing move arrows on books & cat!)
        if app.buttons["editShelfButton"].waitForExistence(timeout: 3) {
            app.buttons["editShelfButton"].tap()
            sleep(1)
            attachScreenshot(name: "02_Shelf_EditMode_DragDrop")
            app.buttons["editShelfButton"].tap()
            sleep(1)
        }

        // 3. Open Book Detail (3D Book + Synopsis + Metadata + Anfangen button)
        let firstBookText = app.staticTexts["Iron Flame"]
        if firstBookText.waitForExistence(timeout: 3) {
            firstBookText.tap()
            sleep(1)
            attachScreenshot(name: "03_BookDetail_3D_Synopsis")
            let closeBtn = app.navigationBars.buttons["Schließen"].firstMatch
            if closeBtn.waitForExistence(timeout: 3) {
                closeBtn.tap()
                sleep(1)
            }
        }

        // 4. "Lesen" Tab (Week Cover Strip + Daily Goal + Currently Reading + Tagebuch)
        let lesenTab = app.tabBars.buttons["Lesen"]
        if lesenTab.waitForExistence(timeout: 3) {
            lesenTab.tap()
            sleep(2)
            attachScreenshot(name: "04_Lesen_Tab_Week_Diary")
        }

        // 5. "Lesezeit" Tab (Dog on Bookshelf Room + Cat Winter Room!)
        let readingTab = app.tabBars.buttons["Lesezeit"]
        if readingTab.waitForExistence(timeout: 3) {
            readingTab.tap()
            sleep(2)
            attachScreenshot(name: "05_ReadingRoom_Dog")

            let catBtn = app.buttons["roomTheme_Katze"]
            if catBtn.waitForExistence(timeout: 3) {
                catBtn.tap()
                sleep(1)
                attachScreenshot(name: "06_ReadingRoom_Cat")
            }
        }

        // 6. "Statistik" Tab (Real Cover Calendar + Monat teilen + Streak)
        let statsTab = app.tabBars.buttons["Statistik"]
        if statsTab.waitForExistence(timeout: 3) {
            statsTab.tap()
            sleep(2)
            attachScreenshot(name: "07_Stats_Calendar_Covers")

            app.swipeUp()
            sleep(1)
            attachScreenshot(name: "08_Stats_Streak_Value")
        }

        // 7. "Mehr" Tab
        let moreTab = app.tabBars.buttons["Mehr"]
        if moreTab.waitForExistence(timeout: 3) {
            moreTab.tap()
            sleep(1)
            attachScreenshot(name: "09_More_And_Backup")
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
