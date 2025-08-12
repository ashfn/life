#include <iostream>
#include <sys/ioctl.h>
#include <unistd.h>
#include <bitset>
#include <vector>
#include <random>
#include <format>
#include <chrono>
#include <thread>

#define MAP_SIZE 50
typedef std::vector<std::bitset<MAP_SIZE> > map_t;

int t = 0;

void printMap(map_t& map){
  for(int r=0; r<MAP_SIZE; r+=4){
    for(int c=0; c<MAP_SIZE; c+=2){
      uint8_t values[8] = {0,3,1,4,2,5,6,7};
      std::bitset<8> braille(0);
      for(int i=0; i<8; i++){
        int row = r+(i / 2);
        int col = c+(i % 2);
        if(map[row][col]){
          braille[values[i]]=1;
        }
      }
      uint8_t sum = braille.to_ullong();
      char utf8[4] = {0};
      uint16_t codepoint = 0x2800 + sum;
      utf8[0] = 0xE2;
      utf8[1] = 0x80 | ((codepoint >> 6) & 0x3F);
      utf8[2] = 0x80 | (codepoint & 0x3F);
      std::cout << utf8;
    }
    std::cout << "\n";
  }
}

void nextRound(map_t& map){

  map_t new_map = map;
  int killed = 0;
  int born = 0;
  for(int r=0; r<MAP_SIZE; r++){
    for(int c=0; c<MAP_SIZE; c++){
      if(r==0 || r==MAP_SIZE-1 || c==0 || c==MAP_SIZE-1){
        new_map[r][c] = 0;
        continue;
      }
      int neighbors = 0;
      for(int rm=-1; rm<2; rm++){
        for(int cm=-1; cm<2; cm++){
          if(!(rm==0 && cm==0)){
            neighbors+=map[r+rm][c+cm];
          }
        }
      }
      if(map[r][c]){
        if(neighbors<2 || neighbors > 3){
          new_map[r][c]=0;
          killed++;
        }
      }else{
        if(neighbors==3){
          new_map[r][c]=1;
          born++;
        }
      }
    }
  }

  int alive = 0;


  for(int r=0; r<MAP_SIZE; r++){
    for(int c = 0; c<MAP_SIZE; c++){
      map[r][c] = new_map[r][c];
      if(map[r][c]) alive++;
    }
    map[r] = new_map[r];
  }

  std::cout << "\x1B]0;Killed: "<<killed << ", Born: "<<born<<", Alive: "<<alive<<", T="<<t<<"\x07";
} 

int main(){

  map_t map(MAP_SIZE, std::bitset<MAP_SIZE>());
  std::random_device rd;
  auto mt = std::mt19937(rd());

  for(int r=0; r<MAP_SIZE; r++){
    for(int c=0; c<MAP_SIZE; c++){
      map[r][c] = (mt()%10)==1;
    }
  }

  while(1){
    printMap(map);
    nextRound(map);
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    std::cout << "\x1B[2J\x1B[H" << std::flush;
    t++;
  }
}
