import XCTest

final class NovelyPrivateUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Clip 1: Bookshelf, Shelf Tabs, Edit Mode, Customizer, TBR Dice & 3D Book Detail

    @MainActor
    func test01_BookshelfAnd3DBookDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        // Wait for concurrent Apple Books + Google Books real cover hydration
        sleep(7)
        attachScreenshot(name: "01_Bookshelf_WarmWood_Cat_Plant")

        // Gentle scroll down & up on Gelesen shelf
        app.swipeUp()
        usleep(900_000)
        app.swipeDown()
        sleep(1)

        // Switch shelf tabs smoothly
        let unreadTab = app.buttons["shelfTab_Ungelesen"]
        if unreadTab.waitForExistence(timeout: 3) {
            unreadTab.tap()
            usleep(1_500_000)
        }
        let currentTab = app.buttons["shelfTab_Aktuell"]
        if currentTab.waitForExistence(timeout: 3) {
            currentTab.tap()
            usleep(1_500_000)
        }
        let readTab = app.buttons["shelfTab_Gelesen"]
        if readTab.waitForExistence(timeout: 3) {
            readTab.tap()
            usleep(1_500_000)
        }

        // Toggle Bearbeiten (Edit Mode) showing move arrows on books & cat
        let editBtn = app.buttons["editShelfButton"]
        if editBtn.waitForExistence(timeout: 3) {
            editBtn.tap()
            usleep(1_600_000)
            attachScreenshot(name: "02_Shelf_EditMode_DragDrop")
            editBtn.tap()
            sleep(1)
        }

        // Open Shelf Customizer ("Regal gestalten")
        let customBtn = app.buttons["customizeShelfButton"]
        if customBtn.waitForExistence(timeout: 3) {
            customBtn.tap()
            usleep(1_800_000)
            let doneBtn = app.navigationBars.buttons["Fertig"].firstMatch
            if doneBtn.waitForExistence(timeout: 3) {
                doneBtn.tap()
                sleep(1)
            }
        }

        // Open TBR Randomizer Dice
        let diceBtn = app.buttons["tbrRandomizerButton"]
        if diceBtn.waitForExistence(timeout: 3) {
            diceBtn.tap()
            usleep(1_500_000)
            let rerollBtn = app.buttons["Neu würfeln"].firstMatch
            if rerollBtn.exists {
                rerollBtn.tap()
                sleep(1)
            }
            app.swipeDown(velocity: .fast)
            sleep(1)
        }

        // Tap Iron Flame to open 3D Book Detail and rotate live!
        let ironFlameBtn = app.buttons["bookItem_Iron Flame"].firstMatch
        if ironFlameBtn.waitForExistence(timeout: 3) {
            ironFlameBtn.tap()
        } else if app.otherElements["bookItem_Iron Flame"].firstMatch.exists {
            app.otherElements["bookItem_Iron Flame"].firstMatch.tap()
        }

        usleep(1_500_000)
        let stage = app.otherElements["book3DStage"].firstMatch
        if stage.waitForExistence(timeout: 3) {
            let start = stage.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.45))
            let left = stage.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.45))
            let right = stage.coordinate(withNormalizedOffset: CGVector(dx: 0.80, dy: 0.45))
            start.press(forDuration: 0.05, thenDragTo: left)
            usleep(700_000)
            left.press(forDuration: 0.05, thenDragTo: right)
            usleep(700_000)
        }

        attachScreenshot(name: "03_BookDetail_3D_Synopsis")
        app.swipeUp()
        usleep(1_200_000)

        let closeBtn = app.navigationBars.buttons["Schließen"].firstMatch
        if closeBtn.waitForExistence(timeout: 3) {
            closeBtn.tap()
            sleep(1)
        }
    }

    // MARK: - Clip 2: Live Book Search, Real Cover Fetch & Post-Add Spine Prompt

    @MainActor
    func test02_LiveSearchAndAddBookDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        sleep(6)

        let addBtn = app.buttons["addBookFloatingButton"]
        if addBtn.waitForExistence(timeout: 4) {
            addBtn.tap()
            usleep(1_500_000)
        }

        let searchField = app.textFields["bookSearchField"]
        if searchField.waitForExistence(timeout: 4) {
            searchField.tap()
            searchField.typeText("Verity Colleen Hoover")
            let submitBtn = app.buttons["bookSearchSubmitButton"]
            if submitBtn.exists {
                submitBtn.tap()
            } else {
                searchField.typeText("\n")
            }
            sleep(4)
        }

        let addOnlineBtn = app.buttons["addOnlineBookButton"].firstMatch
        if addOnlineBtn.waitForExistence(timeout: 5) {
            addOnlineBtn.tap()
            sleep(4)
        }
    }

    // MARK: - Clip 3: Lesen Tab, Lesezimmer (Hund/Katze/Regen/Kamin) & Statistik

    @MainActor
    func test03_LesenLesezeitAndStatsDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        sleep(6)

        // 1. Lesen Tab
        let lesenTab = app.tabBars.buttons["Lesen"]
        if lesenTab.waitForExistence(timeout: 3) {
            lesenTab.tap()
            sleep(2)
            attachScreenshot(name: "04_Lesen_Tab_Week_Diary")
            app.swipeUp()
            usleep(1_200_000)
            app.swipeDown()
            sleep(1)

            let progressBtn = app.buttons["Fortschritt"].firstMatch
            if progressBtn.waitForExistence(timeout: 3) {
                progressBtn.tap()
                usleep(1_500_000)
                app.swipeDown(velocity: .fast)
                sleep(1)
            }
        }

        // 2. Lesezeit Tab (Hund, Live Timer, Katze, Regen, Kamin, Room Picker Sheet)
        let readingTab = app.tabBars.buttons["Lesezeit"]
        if readingTab.waitForExistence(timeout: 3) {
            readingTab.tap()
            sleep(2)
            attachScreenshot(name: "05_ReadingRoom_Dog")

            let startBtn = app.buttons["Session starten"].firstMatch
            if startBtn.waitForExistence(timeout: 3) {
                startBtn.tap()
                sleep(2)
            }

            let catBtn = app.buttons["roomTheme_Katze"]
            if catBtn.waitForExistence(timeout: 3) {
                catBtn.tap()
                sleep(2)
                attachScreenshot(name: "06_ReadingRoom_Cat")
            }

            let rainBtn = app.buttons["roomTheme_Regen"]
            if rainBtn.waitForExistence(timeout: 3) {
                rainBtn.tap()
                sleep(2)
                attachScreenshot(name: "06b_ReadingRoom_Rain")
            }

            let kaminBtn = app.buttons["roomTheme_Kamin"]
            if kaminBtn.waitForExistence(timeout: 3) {
                kaminBtn.tap()
                sleep(2)
                attachScreenshot(name: "06c_ReadingRoom_Fireplace")
            }

            let pickerBtn = app.buttons["roomPickerButton"]
            if pickerBtn.waitForExistence(timeout: 3) {
                pickerBtn.tap()
                usleep(1_500_000)
                let doneBtn = app.buttons["Fertig"].firstMatch
                if doneBtn.exists {
                    doneBtn.tap()
                    sleep(1)
                }
            }
        }

        // 3. Statistik Tab (Real Cover Calendar -> Streak & Regalwert)
        let statsTab = app.tabBars.buttons["Statistik"]
        if statsTab.waitForExistence(timeout: 3) {
            statsTab.tap()
            sleep(2)
            attachScreenshot(name: "07_Stats_Calendar_Covers")

            app.swipeUp()
            sleep(2)
            attachScreenshot(name: "08_Stats_Streak_Value")
        }

        // 4. Mehr Tab
        let moreTab = app.tabBars.buttons["Mehr"]
        if moreTab.waitForExistence(timeout: 3) {
            moreTab.tap()
            sleep(2)
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
