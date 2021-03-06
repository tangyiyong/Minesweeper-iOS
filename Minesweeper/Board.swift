//
//  Board.swift
//  Minesweeper
//
//  Created by Thomas Durand on 23/07/2015.
//  Copyright (c) 2015 Thomas Durand. All rights reserved.
//

import Foundation

enum GameDifficulty: String, CustomStringConvertible {
    case Easy, Medium, Hard, Insane
    
    var description: String {
        return self.shortDescription
    }
    
    var shortDescription: String {
        return NSLocalizedString(rawValue.uppercased(), comment: "")
    }
    
    var size: (width: Int, height: Int) {
        switch self {
        case .Easy:
            return (9, 9)
        case .Medium:
            return (9, 11)
        case .Hard:
            return (10, 14)
        case .Insane:
            return (11, 15)
        }
    }
    
    var nbMines: Int {
        switch self {
        case .Easy:
            return 10
        case .Medium:
            return 16
        case .Hard:
            return 26
        case .Insane:
            return 35
        }
    }
    
    static var random: GameDifficulty {
        let rand = Int(arc4random_uniform(UInt32(allValues.count)))
        return allValues[rand]
    }
    
    static func fromInt(_ value: Int) -> GameDifficulty? {
        switch value {
        case 1:
            return .Easy
        case 2:
            return .Medium
        case 3:
            return .Hard
        case 4:
            return .Insane
        default:
            return nil
        }
    }
    
    var toInt: Int {
        switch self {
        case .Easy:
            return 1
        case .Medium:
            return 2
        case .Hard:
            return 3
        case .Insane:
            return 4
        }
    }
    
    static var allValues: [GameDifficulty] {
        return [.Easy, .Medium, .Hard, .Insane]
    }
    
    static var allShortDescValues: [String] {
        return allValues.map({ $0.shortDescription })
    }
}

class Board {
    let difficulty: GameDifficulty
    
    var minesInitialized: Bool
    var gameOver: Bool
    
    var startDate: Date?
    var score: TimeInterval?
    
    var tiles: [Tile]
    
    var height: Int {
        return difficulty.size.height
    }
    
    var width: Int {
        return difficulty.size.width
    }
    
    var nbMines: Int {
        return difficulty.nbMines
    }
    
    var isGameWon: Bool {
        for t in tiles {
            if !t.isRevealed && !t.isMine {
                return false
            }
        }
        
        return true
    }
    
    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        
        // Score purpose
        self.score = nil
        self.startDate = nil
        
        minesInitialized = false
        gameOver = false
        
        tiles = [Tile]()
        for y in 0..<height {
            for x in 0..<width {
                self.tiles.append(Tile(board: self, x: x, y: y))
            }
        }
        
        assert(nbMines < width * height - 9, "Impossible to have more mines than available cases")
    }
    
    func initMines(_ playedTile: Tile?) {
        var possibilities = [Tile]()
        
        var protectedTiles = [Tile]()
        if let playedTile = playedTile {
            protectedTiles.append(contentsOf: self.getNeighbors(playedTile))
            protectedTiles.append(playedTile)
        }
        
        for tile in tiles {
            if !protectedTiles.contains(tile) {
                possibilities.append(tile)
            }
        }
        
        for _ in 0..<nbMines {
            let index = Int(arc4random_uniform(UInt32(possibilities.count)))
            possibilities[index].setMine()
            possibilities.remove(at: index)
        }
        
        // Counting the start of a game
        GameCounter.sharedInstance.countGameStarted(self.difficulty)
        
        minesInitialized = true
        
        startDate = Date()
    }
    
    func isInBoard(_ x: Int, y: Int) -> Bool {
        return x >= 0 && y >= 0 && x < width && y < height
    }
    
    func getIndex(_ x: Int, y: Int) -> Int {
        return y * width + x
    }
    
    func getTile(_ x: Int, y: Int) -> Tile? {
        if isInBoard(x, y: y) {
            return tiles[getIndex(x, y: y)]
        }
        
        return nil
    }
    
    func getNeighbors(_ square: Tile) -> [Tile] {
        var neighbors = [Tile]()
        
        let dx: [Int] = [-1, 0, 1, -1, 1, -1, 0, 1]
        let dy: [Int] = [-1, -1, -1, 0, 0, 1, 1, 1]
        
        for i in 0..<dx.count {
            if let adj = getTile(square.x + dx[i], y: square.y + dy[i]) {
                neighbors.append(adj)
            }
        }
        
        return neighbors
    }
    
    func play(_ x: Int, y: Int) -> [Tile] {
        if let tile = getTile(x, y: y) {
            return play(tile)
        }
        
        return [Tile]()
    }
    
    func play(_ tile: Tile) -> [Tile] {
        var playedTiles = [Tile]()
        
        if !minesInitialized {
            // Initializing the mines, avoiding placing one where we are playing
            initMines(tile)
        }
        
        if !tile.isMarked && !gameOver {
            if !tile.isRevealed {
                tile.isRevealed = true
                playedTiles.append(tile)
                
                if isGameWon {
                    gameOver = true
                    // Counting the game as finished and won
                    GameCounter.sharedInstance.countGameWon(self.difficulty)
                    
                    if let start = startDate {
                        self.score = -start.timeIntervalSinceNow
                        GameCounter.sharedInstance.reportScore(self.score!, forDifficulty: self.difficulty)
                    }
                    startDate = nil
                    
                    return playedTiles
                }
                
                if tile.isMine {
                    gameOver = true
                    startDate = nil
                    // Counting the game as finished
                    GameCounter.sharedInstance.countGameLost(self.difficulty)
                } else if tile.nbMineAround == 0 {
                    for neighbor in getNeighbors(tile) {
                        let tiles = play(neighbor)
                        playedTiles += tiles
                    }
                }
            } else {
                var nbMarked = 0
                let neighbors = getNeighbors(tile)
                for neighbor in neighbors {
                    if neighbor.isMarked {
                        nbMarked += 1
                    }
                }
                if nbMarked == tile.nbMineAround {
                    for neighbor in neighbors {
                        if !neighbor.isRevealed && !neighbor.isMarked {
                            let tiles = play(neighbor)
                            playedTiles += tiles
                        }
                    }
                }
            }
        }
        
        return playedTiles
    }
    
    func mark(_ x: Int, y: Int) -> [Tile] {
        if let tile = getTile(x, y: y) {
            return mark(tile)
        }
        
        return [Tile]()
    }
    
    func mark(_ tile: Tile) -> [Tile] {
        var markedTiles = [Tile]()
        
        // Should not mark if mines are not initialized
        guard self.minesInitialized else { return markedTiles }
        
        if  !gameOver {
            if !tile.isRevealed {
                tile.isMarked = !tile.isMarked
                markedTiles.append(tile)
            } else {
                var nbUnrevealed = 0
                let neighbors = getNeighbors(tile)
                for neighbor in neighbors {
                    if !neighbor.isRevealed {
                        nbUnrevealed += 1
                    }
                }
                if nbUnrevealed == tile.nbMineAround {
                    for neighbor in neighbors {
                        if !neighbor.isRevealed && !neighbor.isMarked {
                            let tiles = mark(neighbor)
                            markedTiles += tiles
                        }
                    }
                }
            }
        }
        return markedTiles
    }
}
