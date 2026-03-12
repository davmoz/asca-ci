cmake_minimum_required(VERSION 3.10)

set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

project(tfs)

add_subdirectory(src)
add_executable(tfs ${tfs_SRC})

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Issue #120: Use target_compile_options (after add_executable) instead of the
# global add_compile_options, so flags only apply to this target.
if (NOT WIN32)
    target_compile_options(tfs PRIVATE -Wall -Werror -pipe -fvisibility=hidden)
endif ()

if (CMAKE_COMPILER_IS_GNUCXX)
    target_compile_options(tfs PRIVATE -fno-strict-aliasing)
endif ()

# Issue #118: Upgrade from C++11 to C++17. TFS 1.3 builds cleanly with C++17
# on GCC 7+, Clang 5+, and MSVC 2017+. This unlocks std::optional,
# std::string_view, structured bindings, and other modern features.
set_target_properties(tfs PROPERTIES CXX_STANDARD 17)
set_target_properties(tfs PROPERTIES CXX_STANDARD_REQUIRED ON)

# Issue #113: CMake 3.16+ is now widely available and supports
# target_precompile_headers natively. The cotire fallback has been removed.
# If building with CMake < 3.16, upgrade CMake instead of relying on cotire.
if (${CMAKE_VERSION} VERSION_GREATER "3.16.0")
    target_precompile_headers(tfs PUBLIC src/otpch.h)
else ()
    message(WARNING "CMake >= 3.16 is required for precompiled header support. "
                    "Consider upgrading CMake. The cotire fallback has been removed.")
endif ()

set(CMAKE_CXX_FLAGS_PERFORMANCE "${CMAKE_CXX_FLAGS_RELEASE} -march=native")

# Find packages.
find_package(CryptoPP QUIET)
if (CryptoPP_FOUND)  # vcpkg-provided cmake package called CryptoPP
    set(Crypto++_LIBRARIES "cryptopp-static")
else()
    find_package(Crypto++ REQUIRED)
endif ()
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

find_package(Boost 1.53.0 REQUIRED COMPONENTS date_time system filesystem iostreams)

include_directories(${Boost_INCLUDE_DIRS} ${Crypto++_INCLUDE_DIR} ${LUA_INCLUDE_DIR} ${MYSQL_INCLUDE_DIR} ${PUGIXML_INCLUDE_DIR})
target_link_libraries(tfs PRIVATE
        Boost::date_time
        Boost::system
        Boost::filesystem
        Boost::iostreams
        ${CMAKE_THREAD_LIBS_INIT}
        ${Crypto++_LIBRARIES}
        ${LUA_LIBRARIES}
        ${MYSQL_CLIENT_LIBS}
        ${PUGIXML_LIBRARIES}
        )

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
option(BUILD_TESTS "Build unit tests" OFF)
if (BUILD_TESTS)
    add_subdirectory(tests/cpp)
endif ()
### END Tests ###
