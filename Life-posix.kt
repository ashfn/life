@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

// Life.kt  (Kotlin/Native – no coroutines, no JVM APIs)
import kotlinx.cinterop.*
import platform.posix.*

private const val MAP_SIZE = 64

// ---------------------------------------------------------------------------
// Life grid
// ---------------------------------------------------------------------------
private class Game {
    private val grid  = Array(MAP_SIZE) { BooleanArray(MAP_SIZE) }
    private val next  = Array(MAP_SIZE) { BooleanArray(MAP_SIZE) }
    private var t = 0

    init {
        for (r in 0 until MAP_SIZE) {
            for (c in 0 until MAP_SIZE) {
                grid[r][c] = (rand() % 10 == 1)
            }
        }
    }

    // -----------------------------------------------------------------------
    // Render via stdout
    // -----------------------------------------------------------------------
    private fun render() {
        val dotMap = intArrayOf(0, 3, 1, 4, 2, 5, 6, 7)
        for (r in 0 until MAP_SIZE step 4) {
            for (c in 0 until MAP_SIZE step 2) {
                var pattern = 0
                for (i in 0 until 8) {
                    val row = r + (i shr 1)
                    val col = c + (i and 1)
                    if (row < MAP_SIZE && col < MAP_SIZE && grid[row][col]) {
                        pattern = pattern or (1 shl dotMap[i])
                    }
                }
                val codepoint = 0x2800 + pattern
                val utf8 = byteArrayOf(
                    0xE2.toByte(),
                    (0x80 or ((codepoint shr 6) and 0x3F)).toByte(),
                    (0x80 or (codepoint and 0x3F)).toByte()
                )
                write(1, utf8.refTo(0), utf8.size.toULong())
            }
            println()
        }
    }

    // -----------------------------------------------------------------------
    // Conway step
    // -----------------------------------------------------------------------
    private fun step() {
        var killed = 0
        var born   = 0

        for (r in 0 until MAP_SIZE) {
            for (c in 0 until MAP_SIZE) {
                if (r == 0 || r == MAP_SIZE - 1 || c == 0 || c == MAP_SIZE - 1) {
                    next[r][c] = false
                    continue
                }
                var neighbors = 0
                for (dr in -1..1) {
                    for (dc in -1..1) {
                        if (dr == 0 && dc == 0) continue
                        if (grid[r + dr][c + dc]) neighbors++
                    }
                }
                val alive = grid[r][c]
                next[r][c] = when {
                    alive && (neighbors == 2 || neighbors == 3) -> true
                    !alive && neighbors == 3 -> {
                        born++
                        true
                    }
                    alive -> {
                        killed++
                        false
                    }
                    else -> false
                }
            }
        }

        // copy next → grid
        for (r in 0 until MAP_SIZE) {
            for (c in 0 until MAP_SIZE) {
                grid[r][c] = next[r][c]
            }
        }
        t++

        val alive = grid.sumOf { row -> row.count { it } }
        print("\u001B]0;Killed: $killed, Born: $born, Alive: $alive, T=$t\u0007")
    }

    // -----------------------------------------------------------------------
    // Main loop (blocking)
    // -----------------------------------------------------------------------
    fun runForever() {
        while (true) {
            print("\u001B[2J\u001B[H")
            render()
            step()
            usleep(10_000u)   // 10 ms
        }
    }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
fun main() {
    Game().runForever()
}