cmake_minimum_required(VERSION 3.10)
project(tfs_tests)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch Google Test
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
FetchContent_MakeAvailable(googletest)

# Source directory
set(TFS_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../src")

# Find required packages for building TFS source files
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")

find_package(PugiXML REQUIRED)
find_package(Boost 1.53.0 REQUIRED COMPONENTS date_time system filesystem iostreams)

# We compile only the minimal source files needed for unit tests.
# Many TFS classes have deep dependency chains, so we isolate testable
# functions into standalone test files that re-implement or mock dependencies.

# ---------- test_tools ----------
# tools.cpp depends on configmanager (extern g_config) and otpch.h includes.
# We create a self-contained test that re-implements the pure functions.

add_executable(test_tools test_tools.cpp)
target_include_directories(test_tools PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_tools PRIVATE gtest gtest_main ${PUGIXML_LIBRARIES})

add_executable(test_position test_position.cpp)
target_include_directories(test_position PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_position PRIVATE gtest gtest_main)

add_executable(test_wildcardtree test_wildcardtree.cpp)
target_include_directories(test_wildcardtree PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_wildcardtree PRIVATE gtest gtest_main)

add_executable(test_item test_item.cpp)
target_include_directories(test_item PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_item PRIVATE gtest gtest_main)

add_executable(test_condition test_condition.cpp)
target_include_directories(test_condition PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_condition PRIVATE gtest gtest_main)

add_executable(test_combat test_combat.cpp)
target_include_directories(test_combat PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_combat PRIVATE gtest gtest_main)

add_executable(test_vocation test_vocation.cpp)
target_include_directories(test_vocation PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_vocation PRIVATE gtest gtest_main)

add_executable(test_configmanager test_configmanager.cpp)
target_include_directories(test_configmanager PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_configmanager PRIVATE gtest gtest_main)

add_executable(test_database test_database.cpp)
target_include_directories(test_database PRIVATE ${TFS_SRC_DIR} ${PUGIXML_INCLUDE_DIR} ${Boost_INCLUDE_DIRS})
target_link_libraries(test_database PRIVATE gtest gtest_main)

enable_testing()
add_test(NAME ToolsTest COMMAND test_tools)
add_test(NAME PositionTest COMMAND test_position)
add_test(NAME WildcardTreeTest COMMAND test_wildcardtree)
add_test(NAME ItemTest COMMAND test_item)
add_test(NAME ConditionTest COMMAND test_condition)
add_test(NAME CombatTest COMMAND test_combat)
add_test(NAME VocationTest COMMAND test_vocation)
add_test(NAME ConfigManagerTest COMMAND test_configmanager)
add_test(NAME DatabaseTest COMMAND test_database)
