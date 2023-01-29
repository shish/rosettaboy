cmake_minimum_required(VERSION 3.10)
project(rosettaboy-cpp)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

option(ENABLE_LTO "enable LTO" OFF)
include(CheckIPOSupported)
check_ipo_supported(RESULT supported OUTPUT error)

include(GNUInstallDirs)

include_directories(/usr/local/include/)

add_executable(rosettaboy-cpp src/main.cpp src/args.cpp src/cpu.cpp src/cart.cpp src/gameboy.cpp src/gpu.cpp src/consts.h src/cart.h src/cpu.h src/gpu.h src/args.h src/apu.cpp src/apu.h src/ram.cpp src/ram.h src/buttons.cpp src/buttons.h src/clock.cpp src/clock.h)
install(TARGETS rosettaboy-cpp
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

if( ENABLE_LTO AND supported )
    message(STATUS "IPO / LTO enabled")
    target_compile_options(rosettaboy-cpp PRIVATE -flto)
    target_link_options(rosettaboy-cpp PRIVATE -flto)
    set_property(TARGET rosettaboy-cpp PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
target_link_libraries(rosettaboy-cpp ${SDL2_LIBRARIES})
