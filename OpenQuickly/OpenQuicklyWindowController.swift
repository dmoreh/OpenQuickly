//
//  OpenQuicklyWindowController.swift
//  OpenQuickly
//
//  Created by Luka Kerr on 25/2/19.
//  Copyright © 2019 Luka Kerr. All rights reserved.
//

import Cocoa

open class OpenQuicklyWindowController: NSWindowController {
    let AUTOSAVE_NAME = "OpenQuicklyWindow"

    var options: OpenQuicklyOptions!

    private var windowIsVisible: Bool {
        return window?.isVisible ?? false
    }

    public convenience init(options: OpenQuicklyOptions) {
        let oqvc = OpenQuicklyViewController(options: options)
        let window = OpenQuicklyWindow(contentViewController: oqvc)

        self.init(window: window)

        self.options = options

        if options.persistPosition {
            window.setFrameAutosaveName(self.AUTOSAVE_NAME)
        }
    }

    open override func close() {
        if self.windowIsVisible {
            self.options.delegate?.windowDidClose()
            super.close()
        }
    }

    func show() {
        guard let window = self.window else { return }

        window.makeKeyAndOrderFront(self)
        window.level = .floating
        window.center()
        window.orderFrontRegardless()
        showWindow(self)

        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
    }

    public func toggle() {
        if self.windowIsVisible {
            self.close()
        } else {
            self.show()
        }
    }
}
