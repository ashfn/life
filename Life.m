//
//  Life.m
//
#import <Foundation/Foundation.h>
#import <unistd.h>
#import <stdio.h>

static const NSUInteger MAP_SIZE = 64;

@interface Game : NSObject
- (void)run;
@end

@implementation Game {
    BOOL _grid[MAP_SIZE][MAP_SIZE];
    BOOL _next[MAP_SIZE][MAP_SIZE];
    NSUInteger _t;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _t = 0;
        /* random seed: ~10 % density */
        for (NSUInteger r = 0; r < MAP_SIZE; r++) {
            for (NSUInteger c = 0; c < MAP_SIZE; c++) {
                _grid[r][c] = (arc4random_uniform(10) == 1);
            }
        }
    }
    return self;
}

/* Prints the current grid to stdout using Unicode Braille */
- (void)render {
    const NSUInteger dotMap[8] = {0,3,1,4,2,5,6,7};   // same order as C++
    for (NSUInteger r = 0; r < MAP_SIZE; r += 4) {
        for (NSUInteger c = 0; c < MAP_SIZE; c += 2) {
            unsigned char pattern = 0;
            for (NSUInteger i = 0; i < 8; i++) {
                NSUInteger row = r + (i >> 1);
                NSUInteger col = c + (i & 1);
                if (row < MAP_SIZE && col < MAP_SIZE && _grid[row][col]) {
                    pattern |= (1 << dotMap[i]);
                }
            }
            uint32_t codepoint = 0x2800 + pattern;
            /* UTF-32 → UTF-8 (manual, 3 bytes) */
            unsigned char utf8[4] = {
                0xE2,
                0x80 | ((codepoint >> 6) & 0x3F),
                0x80 | (codepoint & 0x3F),
                0
            };
            printf("%s", utf8);
        }
        putchar('\n');
    }
    fflush(stdout);
}

/* One generation of Conway’s Game of Life */
- (void)step {
    NSUInteger killed = 0, born = 0;

    for (NSUInteger r = 0; r < MAP_SIZE; r++) {
        for (NSUInteger c = 0; c < MAP_SIZE; c++) {
            if (r == 0 || r == MAP_SIZE-1 || c == 0 || c == MAP_SIZE-1) {
                _next[r][c] = NO;
                continue;
            }
            NSUInteger neighbors = 0;
            for (int dr = -1; dr <= 1; dr++) {
                for (int dc = -1; dc <= 1; dc++) {
                    if (dr == 0 && dc == 0) continue;
                    neighbors += _grid[r+dr][c+dc];
                }
            }
            BOOL alive = _grid[r][c];
            if (alive && (neighbors < 2 || neighbors > 3)) {
                _next[r][c] = NO;
                killed++;
            } else if (!alive && neighbors == 3) {
                _next[r][c] = YES;
                born++;
            } else {
                _next[r][c] = alive;
            }
        }
    }
    memcpy(_grid, _next, sizeof(_grid));
    _t++;

    /* Update the terminal’s title bar */
    NSUInteger alive = 0;
    for (NSUInteger r = 0; r < MAP_SIZE; r++) {
        for (NSUInteger c = 0; c < MAP_SIZE; c++) {
            alive += _grid[r][c];
        }
    }
    printf("\033]0;Killed: %lu, Born: %lu, Alive: %lu, T=%lu\007",
           (unsigned long)killed, (unsigned long)born,
           (unsigned long)alive, (unsigned long)_t);
    fflush(stdout);
}

/* Main loop: timer fires every 10 ms */
- (void)run {
    [[NSRunLoop currentRunLoop] addTimer:
     [NSTimer scheduledTimerWithTimeInterval:0.01
                                      target:self
                                    selector:@selector(tick:)
                                    userInfo:nil
                                     repeats:YES]
                                   forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}

- (void)tick:(NSTimer *)timer {
    printf("\033[2J\033[H");  // clear screen + home cursor
    [self render];
    [self step];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [[Game new] run];
    }
    return 0;
}