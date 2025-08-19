//
//  Life.swift
//

import Foundation

// MARK: - Model ---------------------------------------------------------------

/// Represents a living cell by its coordinates.
private struct Point: Hashable {
    let r: Int
    let c: Int
}

/// Conway’s Game of Life on a finite 64×64 grid.
private final class Game {
    /// Logical grid size (must match C++ MAP_SIZE).
    private static let size = 64
    
    /// All currently living cells.
    private var living: Set<Point> = []
    
    /// Current generation counter.
    private var t: Int = 0
    
    init() {
        // Random initial state: ~10 % density.
        var new: Set<Point> = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if Int.random(in: 0..<10) == 1 {
                    new.insert(Point(r: r, c: c))
                }
            }
        }
        living = new
    }
    
    /// Advances simulation by one generation.
    fileprivate func step() {
        var next: Set<Point> = []
        var born  = 0
        var died  = 0
        
        // Iterate over every cell that could change.
        let candidates = Set(
            living.flatMap { p in
                (-1...1).flatMap { dr in
                    (-1...1).map { dc in Point(r: p.r + dr, c: p.c + dc) }
                }
            }
        )
        
        for p in candidates {
            guard (0..<Self.size).contains(p.r),
                  (0..<Self.size).contains(p.c) else { continue }
            
            let neighbors = (-1...1).reduce(0) { sum, dr in
                sum + (-1...1).reduce(0) { innerSum, dc in
                    (dr == 0 && dc == 0) ? innerSum
                        : (living.contains(Point(r: p.r + dr, c: p.c + dc)) ? innerSum + 1 : innerSum)
                }
            }
            
            let currentlyAlive = living.contains(p)
            if currentlyAlive && (neighbors == 2 || neighbors == 3) {
                next.insert(p)
            } else if !currentlyAlive && neighbors == 3 {
                next.insert(p)
                born += 1
            } else if currentlyAlive {
                died += 1
            }
        }
        
        living = next
        t += 1
        
        // Update terminal title.
        let alive = living.count
        print("\u{1B}]0;Killed: \(died), Born: \(born), Alive: \(alive), T=\(t)\u{07}", terminator: "")
        fflush(stdout)
    }
    
    /// Renders the grid to stdout using Unicode Braille.
    fileprivate func render() {
        // 2×4 block → one Braille character.
        let dotMap: [Int] = [0, 3, 1, 4, 2, 5, 6, 7]   // same as C++
        
        for r in stride(from: 0, to: Self.size, by: 4) {
            for c in stride(from: 0, to: Self.size, by: 2) {
                var pattern = 0
                for i in 0..<8 {
                    let row = r + (i >> 1)
                    let col = c + (i & 1)
                    if living.contains(Point(r: row, c: col)) {
                        pattern |= 1 << dotMap[i]
                    }
                }
                let scalar = UnicodeScalar(0x2800 + pattern)!
                print(String(scalar), terminator: "")
            }
            print()
        }
    }
}

// MARK: - Main Loop -----------------------------------------------------------

@main
enum Main {
    static func main() async {
        let game = Game()
        
        while true {
            // Clear screen and move cursor to top-left.
            print("\u{1B}[2J\u{1B}[H", terminator: "")
            game.render()
            game.step()
            
            // 10 ms ≈ 100 FPS.
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
