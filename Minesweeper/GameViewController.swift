//
//  GameViewController.swift
//  Minesweeper
//
//  Created by Thomas Durand on 23/07/2015.
//  Copyright (c) 2015 Thomas Durand. All rights reserved.
//

import Foundation
import SnapKit
import SpriteKit

class GameViewController: UIViewController {
    var scene: GameScene?
    
    var skView: SKView!
    var playOrFlagControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Creating SKView
        skView = SKView(frame: self.view.frame)
        self.view.addSubview(skView)
        skView.snp_makeConstraints(closure: { (make) -> Void in
            make.edges.equalTo(self.view).inset(UIEdgeInsetsMake(0, 0, 0, 0))
        })
        
        // Creating Top bar buttons
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "New Game", style: .Plain, target: self, action: "gameButtonPressed:")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .Plain, target: self, action: "showSettings:")
        
        // Creating segmented toolbar
        playOrFlagControl = UISegmentedControl(items: ["Dig", "Flag"])
        playOrFlagControl.setWidth(100, forSegmentAtIndex: 0)
        playOrFlagControl.setWidth(100, forSegmentAtIndex: 1)
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        let segmItem = UIBarButtonItem(customView: playOrFlagControl)
        
        self.toolbarItems = [space, segmItem, space]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.performSettingsChanges()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.performDifficultyChanges()
    }
    
    func performSettingsChanges() {
        if Settings.markWithLongPressEnabled && Settings.bottomBarHidden {
            self.playOrFlagControl.selectedSegmentIndex = 0
            self.navigationController!.toolbarHidden = true
        } else {
            self.navigationController!.toolbarHidden = false
        }
    }
    
    func performDifficultyChanges() {
        if (scene != nil) {
            if (Settings.difficulty != self.scene!.board.difficulty) {
                startGame()
            }
        } else {
            startGame()
        }
    }
    
    func startGame() {
        if (!Settings.difficulty.difficultyAvailable) {
            // TODO: should present avantages of paid version :-)
            Settings.difficulty = .Easy
        }
        newGame( Settings.difficulty )
    }
    
    func newGame(difficulty: GameDifficulty) {
        // Reinit segmented control
        self.playOrFlagControl.selectedSegmentIndex = 0
        
        // Configure the view.
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        let newScene = GameScene(size: skView.frame.size, controller: self, difficulty: difficulty)
        newScene.scaleMode = .AspectFill
        
        // Present the scene.
        skView.presentScene(newScene)
        scene = newScene
    }
    
    func gameButtonPressed(sender: AnyObject) {
        startGame()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let scene = self.scene {
            scene.size = self.skView.frame.size
        }
    }
    
    func showSettings(sender: UIBarButtonItem) {
        let viewController = SettingsViewController()
        viewController.parentVC = self
        let navController = UINavigationController(rootViewController: viewController)
        
        if (UI_USER_INTERFACE_IDIOM() == .Pad) {
            let popover = UIPopoverController(contentViewController: navController)
            popover.presentPopoverFromBarButtonItem(sender, permittedArrowDirections: .Any, animated: true)
        } else {
            self.presentViewController(navController, animated: true, completion: nil)
        }
    }
}