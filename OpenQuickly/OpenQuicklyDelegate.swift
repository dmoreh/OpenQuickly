//
//  OpenQuicklyDelegate.swift
//  OpenQuickly
//
//  Created by Luka Kerr on 25/2/19.
//  Copyright © 2019 Luka Kerr. All rights reserved.
//

import Cocoa
import Foundation

public protocol OpenQuicklyDelegate {
    /// Called when an item in the matches list was selected
    ///
    /// - Parameters:
    ///   - item: The selected item
    func didSelectItem(_ item: Any)

    /// Called when a value was typed in the search bar
    ///
    /// - Parameters:
    ///   - value: The value entered in to the search field
    ///
    /// - Returns: Any matches based off the value typed
    func matchesForSearchQuery(_ query: String) -> [Any]

    /// Given an item return a view to be used for that item in the matches list
    ///
    /// - Parameters:
    ///   - item: An item from the matches list
    ///
    /// - Returns: A view to display the given item in the matches list
    func viewForItem(_ item: Any) -> NSView?

    /// Called when the open quickly window is closed
    func windowDidClose()
}

extension OpenQuicklyDelegate {
    func windowDidClose() {}
}
