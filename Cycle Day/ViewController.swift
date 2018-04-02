//
//  ViewController.swift
//  Cycle Day
//
//  Created by Evan I. Trowbridge on 3/22/18.
//  Copyright © 2018 TrowLink. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var cycleDayOutput: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func setCycleDayPopover(cycleDayText: String){
        cycleDayOutput.stringValue = cycleDayText
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

