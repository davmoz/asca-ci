cmake_minimum_required(VERSION 3.19)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if (NOT WIN32)
    target_compile_options(tfs PRIVATE -Wall -Wextra -Werror -pipe -fvisibility=hidden
        -Wnon-virtual-dtor -Woverloaded-virtual -Wpedantic)
endif ()

if (CMAKE_COMPILER_IS_GNUCXX)
    target_compile_options(tfs PRIVATE -fno-strict-aliasing
        -Wduplicated-cond -Wlogical-op)
endif ()

target_precompile_headers(tfs PUBLIC src/otpch.h)

# Issue 232: Unity build support — groups source files to speed compilation
option(ENABLE_UNITY_BUILD "Enable unity (jumbo) builds" ON)
if (ENABLE_UNITY_BUILD)
    set_target_properties(tfs PROPERTIES UNITY_BUILD ON)
endif ()

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")

# Find packages.
find_package(OpenSSL 3.0.0 REQUIRED)
find_package(fmt REQUIRED)
find_package(MySQL REQUIRED)
find_package(Threads REQUIRED)
find_package(PugiXML REQUIRED)

# Selects LuaJIT if user defines or auto-detected
if (DEFINED USE_LUAJIT AND NOT USE_LUAJIT)
    set(FORCE_LUAJIT ${USE_LUAJIT})
else ()
    find_package(LuaJIT)
    set(FORCE_LUAJIT ${LuaJIT_FOUND})
endif ()
option(USE_LUAJIT "Use LuaJIT" ${FORCE_LUAJIT})

if (FORCE_LUAJIT)
    if (APPLE)
        set(CMAKE_EXE_LINKER_FLAGS "-pagezero_size 10000 -image_base 100000000")
    endif ()
else ()
    find_package(Lua REQUIRED)
endif ()

find_package(Boost 1.53.0 REQUIRED COMPONENTS date_time filesystem iostreams)

include_directories(${Boost_INCLUDE_DIRS} ${LUA_INCLUDE_DIR} ${MYSQL_INCLUDE_DIR} ${PUGIXML_INCLUDE_DIR})
target_link_libraries(tfs PRIVATE
        Boost::date_time
        Boost::filesystem
        Boost::iostreams
        ${CMAKE_THREAD_LIBS_INIT}
        OpenSSL::Crypto
        OpenSSL::SSL
        fmt::fmt
        ${LUA_LIBRARIES}
        ${MYSQL_CLIENT_LIBS}
        ${PUGIXML_LIBRARIES}
        )

# Static libmariadb on macOS needs zlib for compression support
if (APPLE)
    find_package(ZLIB)
    if (ZLIB_FOUND)
        target_link_libraries(tfs PRIVATE ZLIB::ZLIB)
    endif ()
endif ()

### INTERPROCEDURAL_OPTIMIZATION ###
cmake_policy(SET CMP0069 NEW)
include(CheckIPOSupported)
check_ipo_supported(RESULT result OUTPUT error)
if (result)
    message(STATUS "IPO / LTO enabled")
    set_target_properties(tfs PROPERTIES INTERPROCEDURAL_OPTIMIZATION True)
else ()
    message(STATUS "IPO / LTO not supported: <${error}>")
endif ()
### END INTERPROCEDURAL_OPTIMIZATION ###

### Git Version ###
# Define the two required variables before including
# the source code for watching a git repository.
set(PRE_CONFIGURE_FILE "cmake/gitmetadata.h.in")
set(POST_CONFIGURE_FILE "${CMAKE_CURRENT_BINARY_DIR}/gitmetadata.h")
include(git_watcher)
if (Git_FOUND)
    add_dependencies(tfs check_git)
    target_include_directories(tfs PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endif()
### END  Git Version ###

### Tests ###
option(BUILD_TESTING "Build unit tests" OFF)
if (BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests/cpp)
    add_subdirectory(src/tests)
endif ()
### END Tests ###
