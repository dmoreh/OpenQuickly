//
//  OpenQuicklyViewController.swift
//  OpenQuickly
//
//  Created by Luka Kerr on 25/2/19.
//  Copyright © 2019 Luka Kerr. All rights reserved.
//

import Cocoa

enum KeyCode {
    static let esc: UInt16 = 53
    static let enter: UInt16 = 36
    static let upArrow: UInt16 = 126
    static let downArrow: UInt16 = 125
    static let n: UInt16 = 45
    static let p: UInt16 = 35
}

class OpenQuicklyViewController: NSViewController, NSTextFieldDelegate {
    /// KeyCodes that shouldn't update the searchField
    let IGNORED_KEYCODES = [
        KeyCode.esc, KeyCode.enter,
        KeyCode.upArrow, KeyCode.downArrow,
    ]

    let IGNORED_WITH_CONTROL_KEYCODES = [
        KeyCode.n, KeyCode.p
    ]

    /// The data used to display the matches
    private var matches: [Any]!

    /// Configuration options
    private var options: OpenQuicklyOptions!

    /// The currently selected match
    private var selected: Int?

    /// Various views
    private var clipView: NSClipView!
    private var stackView: NSStackView!
    private var scrollView: NSScrollView!
    private var searchField: NSTextField!
    private var matchesList: NSOutlineView!
    private var transparentView: NSVisualEffectView!

    /// The Open Quickly window controller instance for this view
    private var openQuicklyWindowController: OpenQuicklyWindowController? {
        return view.window?.windowController as? OpenQuicklyWindowController
    }

    init(options: OpenQuicklyOptions) {
        super.init(nibName: nil, bundle: nil)

        self.options = options
        self.matches = []
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        let frame = NSRect(
            x: 0,
            y: 0,
            width: options.width,
            height: self.options.height
        )

        view = NSView()
        view.frame = frame
        view.wantsLayer = true
        view.layer?.cornerRadius = self.options.radius + 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSearchField()
        self.setupTransparentView()
        self.setupMatchesListView()
        self.setupScrollView()
        self.setupStackView()

        self.stackView.addArrangedSubview(self.searchField)
        self.stackView.addArrangedSubview(self.scrollView)
        self.transparentView.addSubview(self.stackView)
        view.addSubview(self.transparentView)

        self.setupConstraints()

        self.matchesList.doubleAction = #selector(self.itemSelected)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: self.keyDown)
    }

    override func viewWillAppear() {
        self.searchField.stringValue = ""

        if !self.options.persistMatches {
            self.clearMatches()
        }

        view.window?.makeFirstResponder(self.searchField)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    func keyDown(with event: NSEvent) -> NSEvent? {
        guard let window = self.view.window, window.isVisible else { return event }

        let keyCode = event.keyCode

        // When esc pressed, close the window
        if keyCode == KeyCode.esc {
            self.openQuicklyWindowController?.toggle()
            return nil
        }

        // When enter pressed, indicate that an item was selected
        if keyCode == KeyCode.enter {
            self.itemSelected()
            return nil
        }

        // When down arrow pressed, if there is a selection move it down
        if keyCode == KeyCode.downArrow || (keyCode == KeyCode.n && event.isHoldingControl) {
            if let currentSelection = selected {
                self.setSelected(at: currentSelection + 1)
            }

            return nil
        }

        // When uo arrow pressed, if there is a selection move it up
        if keyCode == KeyCode.upArrow || (keyCode == KeyCode.p && event.isHoldingControl) {
            if let currentSelection = selected {
                self.setSelected(at: currentSelection - 1)
            }

            return nil
        }

        return event
    }

    override func keyUp(with event: NSEvent) {
        if self.IGNORED_KEYCODES.contains(event.keyCode) || (event.isHoldingControl && self.IGNORED_WITH_CONTROL_KEYCODES.contains(event.keyCode)) {
            return
        }

        let query = self.searchField.stringValue

        self.matches = self.options.delegate?.matchesForSearchQuery(query)

        self.reloadMatches()
    }

    @objc func itemSelected() {
        let selectedItem = self.matchesList.item(atRow: self.matchesList.selectedRow) as Any

        if let delegate = options.delegate {
            delegate.didSelectItem(selectedItem)
        }

        self.openQuicklyWindowController?.toggle()
    }

    // MARK: - UI management

    private func clearMatches() {
        self.matches = []
        self.reloadMatches()
    }

    private func reloadMatches() {
        self.matchesList.reloadData()
        self.updateViewSize()

        if self.matches.count > 0 {
            self.setSelected(at: 0)
        }
    }

    private func setSelected(at index: Int) {
        if index < 0 || index >= self.matches.count {
            return
        }

        self.selected = index
        let selectedIndex = IndexSet(integer: index)
        matchesList.scrollRowToVisible(index)
        self.matchesList.selectRowIndexes(selectedIndex, byExtendingSelection: false)
    }

    private func updateViewSize() {
        let numMatches = self.matches.count > self.options.matchesShown
            ? self.options.matchesShown : self.matches.count

        let rowHeight = CGFloat(numMatches) * self.options.rowHeight
        let newHeight = self.options.height + rowHeight

        let newSize = NSSize(width: options.width, height: newHeight)

        guard var frame = view.window?.frame else { return }

        frame.origin.y += frame.size.height
        frame.origin.y -= newSize.height
        frame.size = newSize

        view.setFrameSize(newSize)
        self.transparentView.setFrameSize(newSize)
        view.window?.setFrame(frame, display: true)
        self.stackView.spacing = self.matches.count > 0 ? 5.0 : 0.0
    }

    // MARK: - UI setup

    private func setupSearchField() {
        self.searchField = NSTextField()
        self.searchField.delegate = self
        self.searchField.alignment = .left
        self.searchField.isEditable = true
        self.searchField.isBezeled = false
        self.searchField.isSelectable = true
        self.searchField.font = self.options.font
        self.searchField.focusRingType = .none
        self.searchField.drawsBackground = false
        self.searchField.placeholderString = self.options.placeholder
    }

    private func setupTransparentView() {
        let frame = NSRect(
            x: 0,
            y: 0,
            width: options.width,
            height: self.options.height
        )

        self.transparentView = NSVisualEffectView()
        self.transparentView.frame = frame
        self.transparentView.state = .active
        self.transparentView.wantsLayer = true
        self.transparentView.blendingMode = .behindWindow
        self.transparentView.layer?.cornerRadius = self.options.radius
        self.transparentView.material = self.options.material
    }

    private func setupMatchesListView() {
        self.matchesList = NSOutlineView()
        self.matchesList.delegate = self
        self.matchesList.headerView = nil
        self.matchesList.wantsLayer = true
        self.matchesList.dataSource = self
        self.matchesList.selectionHighlightStyle = .sourceList

        let column = NSTableColumn()
        matchesList.addTableColumn(column)
    }

    private func setupScrollView() {
        self.scrollView = NSScrollView()
        self.scrollView.borderType = .noBorder
        self.scrollView.drawsBackground = false
        self.scrollView.autohidesScrollers = true
        self.scrollView.hasVerticalScroller = true
        self.scrollView.documentView = self.matchesList
        self.scrollView.translatesAutoresizingMaskIntoConstraints = true
    }

    private func setupStackView() {
        self.stackView = NSStackView()
        self.stackView.spacing = 0.0
        self.stackView.orientation = .vertical
        self.stackView.distribution = .fillEqually
        self.stackView.edgeInsets = self.options.edgeInsets
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        let stackViewConstraints = [
            stackView.topAnchor.constraint(equalTo: self.transparentView.topAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.transparentView.bottomAnchor),
            self.stackView.leadingAnchor.constraint(equalTo: self.transparentView.leadingAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.transparentView.trailingAnchor),
        ]

        NSLayoutConstraint.activate(stackViewConstraints)
    }
}

extension OpenQuicklyViewController: NSOutlineViewDataSource {
    /// Number of items in the matches list
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return self.matches.count
    }

    /// Items to be added to the matches list
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return self.matches[index]
    }

    /// Whether items in the matches list are expandable by an arrow
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }

    /// Height of each item in the matches list
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return self.options.rowHeight
    }

    /// When an item in the matches list is clicked on should it be selected
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return true
    }

    /// The NSTableRowView instance to be used
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return OpenQuicklyTableRowView(frame: NSZeroRect)
    }

    /// When an item is selected
    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.selected = self.matchesList.selectedRow
    }
}

extension OpenQuicklyViewController: NSOutlineViewDelegate {
    /// The view for each item in the matches array
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        return self.options.delegate?.viewForItem(item)
    }
}

extension NSEvent {
    var isHoldingControl: Bool {
        return self.modifierFlags.rawValue & UInt(CGEventFlags.maskControl.rawValue) > 0
    }
}
