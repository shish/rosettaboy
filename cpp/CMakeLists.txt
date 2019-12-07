cmake_minimum_required(VERSION 3.10)
project(spigot)

set(CMAKE_CXX_STANDARD 17)
include_directories(/usr/local/include/)

add_executable(spigot src/main.cpp src/cpu.cpp src/cart.cpp src/gpu.cpp src/consts.h src/cart.h src/cpu.h src/gpu.h src/args.h src/apu.cpp src/apu.h src/ram.cpp src/ram.h src/buttons.cpp src/buttons.h src/clock.cpp src/clock.h)

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
target_link_libraries(spigot ${SDL2_LIBRARIES})
