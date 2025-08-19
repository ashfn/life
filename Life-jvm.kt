// Life.kt
import kotlin.math.min
import kotlin.random.Random
import kotlin.system.exitProcess
import kotlinx.coroutines.*

// ---------------------------------------------------------------------------
// 1. 64 x 64 grid – plain Boolean array for speed
// ---------------------------------------------------------------------------
private const val MAP_SIZE = 64

private class Game {
    private val grid  = Array(MAP_SIZE) { BooleanArray(MAP_SIZE) }
    private val next  = Array(MAP_SIZE) { BooleanArray(MAP_SIZE) }
    private var t = 0

    init {
        // random seed: ~10 % density
        for (r in 0 until MAP_SIZE) {
            for (c in 0 until MAP_SIZE) {
                grid[r][c] = Random.nextInt(10) == 1
            }
        }
    }

    // -----------------------------------------------------------------------
    // 2. Render to stdout using Unicode Braille block characters
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
                // UTF-8 encoding of U+28xx
                val bytes = byteArrayOf(
                    0xE2.toByte(),
                    (0x80 or ((codepoint shr 6) and 0x3F)).toByte(),
                    (0x80 or (codepoint and 0x3F)).toByte()
                )
                kotlin.io.stdout.write(bytes)
            }
            println()
        }
    }

    // -----------------------------------------------------------------------
    // 3. Conway step
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
                for (dr in -1..2) {
                    for (dc in -1..2) {
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

        // swap buffers
        for (r in 0 until MAP_SIZE) {
            System.arraycopy(next[r], 0, grid[r], 0, MAP_SIZE)
        }
        t++

        // update terminal title
        val alive = grid.sumOf { row -> row.count { it } }
        print("\u001B]0;Killed: $killed, Born: $born, Alive: $alive, T=$t\u0007")
    }

    // -----------------------------------------------------------------------
    // 4. Main loop on Dispatchers.Default so we can sleep without blocking
    // -----------------------------------------------------------------------
    suspend fun runForever() {
        while (true) {
            print("\u001B[2J\u001B[H")   // clear screen + home cursor
            render()
            step()
            delay(10)                   // 10 ms
        }
    }
}

// ---------------------------------------------------------------------------
// 5. Entry point
// ---------------------------------------------------------------------------
fun main() = runBlocking {
    try {
        Game().runForever()
    } catch (e: CancellationException) {
        exitProcess(0)
    }
}