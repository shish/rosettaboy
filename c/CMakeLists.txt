cmake_minimum_required(VERSION 3.10)
project(rosettaboy-c)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_FLAGS_RELEASE "-O3")

include(GNUInstallDirs)

option(ENABLE_LTO "enable LTO" OFF)
include(CheckIPOSupported)
check_ipo_supported(RESULT supported OUTPUT error)

include_directories(/usr/local/include/)

set(HEADERS
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
    src/cpu.c
    src/cart.c
    src/gameboy.c
    src/gpu.c
    src/apu.c
    src/ram.c
    src/buttons.c
    src/clock.c
    ${HEADERS})

add_library(rosettaboy-c-shared SHARED ${SOURCE_FILES})
add_library(rosettaboy-c-static STATIC ${SOURCE_FILES})

add_executable(rosettaboy-c
    src/main.c
    src/args.c
    src/args.h
    ${SOURCE_FILES})

if( ENABLE_LTO AND supported )
    message(STATUS "IPO / LTO enabled")
    target_compile_options(rosettaboy-c PRIVATE -flto)
    target_link_options(rosettaboy-c PRIVATE -flto)
    set_property(TARGET rosettaboy-c PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
target_link_libraries(rosettaboy-c-shared ${SDL2_LIBRARIES})
target_link_libraries(rosettaboy-c ${SDL2_LIBRARIES})

install(TARGETS rosettaboy-c rosettaboy-c-shared rosettaboy-c-static
    EXPORT rosettaboy-c
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(FILES ${HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/rosettaboy-c)
install(EXPORT rosettaboy-c DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/cmake)
