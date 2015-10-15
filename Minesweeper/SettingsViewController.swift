//
//  SettingsViewController.swift
//  Minesweeper
//
//  Created by Thomas Durand on 10/08/2015.
//  Copyright (c) 2015 Thomas Durand. All rights reserved.
//

import UIKit
import Eureka
import IAPController

class SettingsViewController: FormViewController {
    
    var parentVC: GameViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "donePressed:")
        
        setupForm()
        
        self.preferredContentSize = CGSizeMake(320, 400)
        
        // TODO: Add observer and treat IAP
        
        // Fetching iAP
        IAPController.sharedInstance.fetchProducts()
    }
    
    func setupForm() {
        form.removeAll()
        
        form +++
            Section("Difficulty")
            <<< PushRow<String>("difficulty") {
                $0.title = "Difficulty"
                $0.options = GameDifficulty.allRawValues
                $0.value = Settings.difficulty.rawValue
            }.onChange { row in
                guard let rawVal = row.value else { return }
                guard let difficulty = GameDifficulty(rawValue: rawVal) else { return }
                Settings.difficulty = difficulty
            }
            
            +++ Section("Gameplay")
            <<< SwitchRow("vibrate") {
                $0.title = "Vibrations"
                $0.value = Settings.vibrationEnabled
                $0.hidden = .Function(["vibrate"], { form in
                    return UIDevice.currentDevice().model != "iPhone"
                })
            }.onChange{ row in
                guard let vibrate = row.value else { return }
                Settings.vibrationEnabled = vibrate
            }
            
            <<< SwitchRow("longPress") {
                $0.title = "Mark with long press"
                $0.value = Settings.markWithLongPressEnabled
            }.onChange{ row in
                guard let longPress = row.value else { return }
                Settings.markWithLongPressEnabled = longPress
            }
            
            <<< SwitchRow("hiddenToolbar") {
                $0.title = "Hide toolbar"
                $0.value = Settings.bottomBarHidden
                $0.hidden = .Function(["longPress"], { form in
                    if let r1 : SwitchRow = form.rowByTag("longPress") {
                        return r1.value == false
                    }
                    return true
                })
            }.onChange{ row in
                guard let hideToolbar = row.value else { return }
                Settings.bottomBarHidden = hideToolbar
            }
        
            +++ Section("Premium Features")
            <<< ButtonRow("buy") {
                    $0.title = "Unlock all features"
            }.onCellSelection { cell, row in
                if let indexPath = self.tableView!.indexPathForSelectedRow {
                    self.tableView!.deselectRowAtIndexPath(indexPath, animated: true)
                }
                
                guard let product = IAPController.sharedInstance.products?.first else { return }
                product.buy()
            }
            <<< ButtonRow("restore") {
                $0.title = "Restore previous purchase"
            }.onCellSelection { cell, row in
                if let indexPath = self.tableView!.indexPathForSelectedRow {
                    self.tableView!.deselectRowAtIndexPath(indexPath, animated: true)
                }
                
                IAPController.sharedInstance.restore()
            }
    }
    
    func donePressed(sender: AnyObject) {
        if let parent = parentVC {
                parent.performSettingsChanges()
                parent.performDifficultyChanges()
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
