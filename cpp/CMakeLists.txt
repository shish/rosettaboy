cmake_minimum_required(VERSION 3.10)
project(rosettaboy-cpp)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include(GNUInstallDirs)

option(ENABLE_LTO "enable LTO" OFF)
include(CheckIPOSupported)
check_ipo_supported(RESULT supported OUTPUT error)

include_directories(/usr/local/include/)

set(HEADERS
    src/_args.h
    src/args.h
    src/consts.h
    src/cpu.h
    src/cart.h
    src/gameboy.h
    src/gpu.h
    src/apu.h
    src/ram.h
    src/buttons.h
    src/clock.h)

set(SOURCE_FILES
    src/args.cpp
    src/cpu.cpp
    src/cart.cpp
    src/gameboy.cpp
    src/gpu.cpp
    src/apu.cpp
    src/ram.cpp
    src/buttons.cpp
    src/clock.cpp
    ${HEADERS})

add_executable(rosettaboy-cpp
    src/main.cpp
    ${SOURCE_FILES})

if( ENABLE_LTO AND supported )
    message(STATUS "IPO / LTO enabled")
    target_compile_options(rosettaboy-cpp PRIVATE -flto)
    target_link_options(rosettaboy-cpp PRIVATE -flto)
    set_property(TARGET rosettaboy-cpp PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

find_package(fmt REQUIRED)
find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
target_link_libraries(rosettaboy-cpp ${SDL2_LIBRARIES} fmt::fmt-header-only)

install(TARGETS rosettaboy-cpp
    EXPORT rosettaboy-cpp
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(FILES ${HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/rosettaboy-cpp)
install(EXPORT rosettaboy-cpp DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/cmake)
