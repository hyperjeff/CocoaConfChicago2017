//
//  AppDelegate.swift
//  OthelloLife
//
//  Created by Jeff Biggus on 4/16/17.
//  Copyright © 2017 HyperJeff, Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func reset(_ sender: Any) {
		let vc = NSApp.mainWindow?.windowController?.contentViewController as! ViewController
		vc.reset()
	}
}

