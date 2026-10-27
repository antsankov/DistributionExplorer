import XCTest

final class DistributionExplorerUITests: XCTestCase {
    @MainActor
    private func launchExplorer(_ app: XCUIApplication) {
        app.launch()
        let next = app.buttons["onboarding.continue"]
        if next.waitForExistence(timeout: 2) {
            next.tap()
            app.buttons["onboarding.education.undisclosed"].tap()
        }
    }

    @MainActor
    func testFitSamplesLiveRankingAndValidation() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        app.buttons["fit.open"].tap()
        let input = app.textViews["fit.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("-2, -1, 0, 1, 2")
        app.buttons["Done"].tap()
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["fit.result.Normal"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "fit-normal"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.swipeDown()
        app.buttons["fit.clear"].tap()
        input.tap()
        input.typeText("1, invalid, 2")
        app.buttons["Done"].tap()
        app.swipeUp()
        let message = app.staticTexts["fit.message"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertTrue(message.label.contains("not a supported number"))
        XCTAssertFalse(app.descendants(matching: .any)["fit.result.Normal"].exists)
    }

    @MainActor
    func testFitFrequencyCounts() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        app.buttons["fit.open"].tap()
        app.buttons["fit.kind"].tap()
        app.buttons["Counts"].tap()
        app.buttons["fit.format"].tap()
        app.buttons["Value / frequency"].tap()
        let input = app.textViews["fit.input"]
        input.tap()
        input.typeText("0, 4\n1, 4")
        app.buttons["Done"].tap()
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["fit.result.Bernoulli"].waitForExistence(timeout: 5))
        for _ in 0..<3 {
            if app.staticTexts["Compare the shapes"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Compare the shapes"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "fit-frequency-counts"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let model = app.buttons["fit.qq.model"]
        for _ in 0..<4 {
            if model.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(model.isHittable)
        model.tap()
        app.buttons["Geometric"].tap()
        XCTAssertTrue(model.label.contains("Geometric") || (model.value as? String)?.contains("Geometric") == true)
        XCTAssertFalse(app.progressIndicators["fit.loading"].exists)
        let qq = XCTAttachment(screenshot: app.screenshot())
        qq.name = "fit-qq-geometric"
        qq.lifetime = .keepAlways
        add(qq)
    }

    @MainActor
    func testOnboardingCompletionAndReplay() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        let introduction = app.buttons["onboarding.replay"]
        XCTAssertTrue(introduction.waitForExistence(timeout: 5))
        introduction.tap()
        XCTAssertTrue(app.staticTexts["Understand what formulas mean"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["What’s your level of education?"].waitForExistence(timeout: 5))
        app.buttons["onboarding.education.undergraduate"].tap()
        XCTAssertTrue(app.buttons["distribution.normal"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["distribution.normal"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboarding.continue"].exists)
    }

    @MainActor
    func testFinishedControlsAndPanelOrder() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        let normal = app.buttons["distribution.normal"]
        XCTAssertTrue(normal.waitForExistence(timeout: 5))
        normal.tap()
        let playback = app.buttons["playback"]
        let replay = app.buttons["replay"]
        XCTAssertTrue(playback.waitForExistence(timeout: 5))
        let initialLock = app.buttons["balls.reset"]
        XCTAssertEqual(initialLock.label, "Keep balls locked")
        XCTAssertEqual(initialLock.value as? String, "Locked until the curve finishes")
        expectation(for: NSPredicate(format: "value == %@", "Finished"), evaluatedWith: playback)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(replay.label, "Replay")
        let ballControl = app.buttons["balls.reset"]
        XCTAssertTrue(ballControl.isHittable)
        XCTAssertEqual(ballControl.label, "Lock balls")
        XCTAssertGreaterThan(ballControl.frame.minX, replay.frame.minX)
        ballControl.tap()
        XCTAssertEqual(ballControl.label, "Unlock balls")
        XCTAssertEqual(ballControl.value as? String, "Kept locked")
        XCTAssertEqual(playback.value as? String, "Finished")
        ballControl.tap()
        XCTAssertEqual(ballControl.label, "Lock balls")
        XCTAssertEqual(playback.frame.width, replay.frame.width, accuracy: 1)
        XCTAssertEqual(playback.frame.height, replay.frame.height, accuracy: 1)
        XCTAssertEqual(playback.frame.minY, replay.frame.minY, accuracy: 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "finished-controls-dark"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        playback.tap()
        XCTAssertEqual(playback.label, "Pause")
        playback.tap()
        XCTAssertEqual(playback.label, "Play")
        replay.tap()
        XCTAssertEqual(playback.label, "Pause")
        app.swipeUp()
        app.buttons["Parameters"].tap()
        XCTAssertLessThan(app.buttons["Parameters"].frame.minY,
                          app.buttons["Examples in nature & society"].frame.minY)
    }

    @MainActor
    func testBallLockPersistsAfterCurveUntilUnlocked() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        app.buttons["distribution.normal"].tap()
        let control = app.buttons["balls.reset"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        XCTAssertEqual(control.label, "Keep balls locked")
        control.tap()
        XCTAssertEqual(control.label, "Unlock balls")
        XCTAssertEqual(control.value as? String, "Kept locked")
        let playback = app.buttons["playback"]
        expectation(for: NSPredicate(format: "value == %@", "Finished"), evaluatedWith: playback)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(control.label, "Unlock balls")
        XCTAssertEqual(control.value as? String, "Kept locked")
        control.tap()
        XCTAssertEqual(control.label, "Lock balls")
        XCTAssertEqual(control.value as? String, "Unlocked")
        app.buttons["replay"].tap()
        XCTAssertEqual(control.label, "Keep balls locked")
        XCTAssertEqual(control.value as? String, "Locked until the curve finishes")
        playback.tap()
        XCTAssertEqual(control.value as? String, "Locked until the curve finishes")
    }

    @MainActor
    func testPlaybackCompletesWhileGraphIsOffscreen() async throws {
        let app = XCUIApplication()
        launchExplorer(app)
        let poisson = app.buttons["distribution.poisson"]
        XCTAssertTrue(poisson.waitForExistence(timeout: 5))
        poisson.tap()
        let playback = app.buttons["playback"]
        XCTAssertTrue(playback.waitForExistence(timeout: 5))
        app.buttons["1×"].tap()
        app.buttons["replay"].tap()
        playback.tap()
        XCTAssertEqual(playback.label, "Play")
        try await Task.sleep(for: .seconds(0.5))
        XCTAssertEqual(playback.label, "Play")
        playback.tap()
        XCTAssertEqual(playback.label, "Pause")
        app.swipeUp()
        app.swipeUp()
        try await Task.sleep(for: .seconds(10))
        app.swipeDown()
        app.swipeDown()
        XCTAssertEqual(playback.label, "Play")
        XCTAssertEqual(playback.value as? String, "Finished")
        playback.tap()
        XCTAssertEqual(playback.label, "Pause")
        playback.tap()
        XCTAssertEqual(playback.label, "Play")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "playback-controls"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testFirstFiveEssentialsAndPlayback() throws {
        checkExperiments(["normal", "binomial", "poisson", "uniform", "exponential"])
    }

    @MainActor
    func testRemainingExperimentsAndPlayback() throws {
        checkExperiments(["studentT", "beta", "gamma", "lognormal", "chiSquare", "bernoulli"])
    }

    @MainActor
    private func checkExperiments(_ names: [String]) {
        let app = XCUIApplication()
        launchExplorer(app)
        for name in names {
            let topic = name
            let row = app.buttons["distribution.\(topic)"]
            for _ in 0..<4 {
                if row.exists && row.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()
            let playback = app.buttons["playback"]
            XCTAssertTrue(playback.waitForExistence(timeout: 5))
            XCTAssertEqual(playback.label, "Pause")
            playback.tap()
            XCTAssertEqual(playback.label, "Play")
            playback.tap()
            XCTAssertEqual(playback.label, "Pause")
            app.buttons["replay"].tap()
            XCTAssertEqual(playback.label, "Pause")
            let attachment = XCTAttachment(screenshot: app.screenshot())
            app.swipeUp()
            let expectedControl = [
                "bernoulli": "Success probability p", "binomial": "Trials n",
                "normal": "Mean μ", "poisson": "Average count λ", "exponential": "Rate λ",
                "uniform": "Minimum a", "studentT": "Degrees of freedom ν",
                "beta": "Shape α", "gamma": "Shape α", "lognormal": "Log-scale mean μ",
                "chiSquare": "Degrees of freedom ν"
            ][name]!
            let slider = app.sliders[expectedControl]
            XCTAssertTrue(slider.waitForExistence(timeout: 3))
            slider.adjust(toNormalizedSliderPosition: 0.75)
            attachment.name = "\(name)-experiment"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.swipeDown()
            app.swipeDown()
        }
    }

    @MainActor
    func testParametersAndCompletedAnimation() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        app.buttons["distribution.normal"].tap()
        app.swipeUp()
        app.sliders["Mean μ"].adjust(toNormalizedSliderPosition: 0.75)
        app.sliders["Standard deviation σ"].adjust(toNormalizedSliderPosition: 0.65)
        let curve = app.switches["showCurve"]
        XCTAssertTrue(curve.waitForExistence(timeout: 3))
        curve.tap()
        curve.tap()
        app.swipeDown()
        app.buttons["2×"].tap()
        app.buttons["replay"].tap()
        let finished = NSPredicate(format: "value == %@", "Finished")
        expectation(for: finished, evaluatedWith: app.buttons["playback"])
        waitForExpectations(timeout: 12)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "normal-completed"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCollapsibleSections() throws {
        let app = XCUIApplication()
        launchExplorer(app)
        let normalScreen = app.navigationBars["Normal"]
        if !normalScreen.waitForExistence(timeout: 1) {
            let normal = app.buttons["distribution.normal"]
            let hittable = NSPredicate(format: "exists == true AND hittable == true")
            expectation(for: hittable, evaluatedWith: normal)
            waitForExpectations(timeout: 5)
            normal.tap()
        }
        XCTAssertTrue(normalScreen.waitForExistence(timeout: 5))
        app.swipeUp()

        let parameters = app.buttons["Parameters"]
        XCTAssertTrue(parameters.waitForExistence(timeout: 3))
        XCTAssertTrue(app.sliders["Mean μ"].exists)
        parameters.tap()
        XCTAssertFalse(app.sliders["Mean μ"].exists)

        let examples = app.buttons["Examples in nature & society"]
        XCTAssertFalse(app.staticTexts["Measurement errors"].exists)
        examples.tap()
        XCTAssertTrue(app.staticTexts["Measurement errors"].waitForExistence(timeout: 3))
        examples.tap()
        XCTAssertFalse(app.staticTexts["Measurement errors"].exists)

        let explanation = app.buttons["What you’re seeing"]
        let explanationText = app.staticTexts["Values near the mean are most likely. The standard deviation controls how widely they spread."]
        explanation.tap()
        XCTAssertTrue(explanationText.waitForExistence(timeout: 3))
        explanation.tap()
        XCTAssertFalse(explanationText.exists)

        parameters.tap()
        XCTAssertTrue(app.sliders["Mean μ"].waitForExistence(timeout: 3))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "collapsible-sections"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
