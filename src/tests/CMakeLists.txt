find_package(Boost 1.53.0 REQUIRED COMPONENTS unit_test_framework)

set(TFS_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Each test is a self-contained executable that re-implements the functions
# under test to avoid pulling in the full TFS dependency graph.

set(boost_tests_SRC
    ${CMAKE_CURRENT_LIST_DIR}/test_tools.cpp
    ${CMAKE_CURRENT_LIST_DIR}/test_sha1.cpp
    ${CMAKE_CURRENT_LIST_DIR}/test_xtea.cpp
    ${CMAKE_CURRENT_LIST_DIR}/test_base64.cpp
)

foreach(test_src ${boost_tests_SRC})
    get_filename_component(test_name ${test_src} NAME_WE)
    set(test_name "boost_${test_name}")
    add_executable(${test_name} ${test_src})
    target_include_directories(${test_name} PRIVATE ${TFS_SRC_DIR})
    target_link_libraries(${test_name} PRIVATE Boost::unit_test_framework)
    target_compile_definitions(${test_name} PRIVATE BOOST_TEST_DYN_LINK)
    # Clear LuaJIT linker flags that leak from the parent scope
    set_target_properties(${test_name} PROPERTIES LINK_FLAGS "")
    add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()

# test_xtea needs the actual xtea.cpp implementation
target_sources(boost_test_xtea PRIVATE ${TFS_SRC_DIR}/xtea.cpp)

# test_base64 needs base64.cpp and OpenSSL
target_sources(boost_test_base64 PRIVATE ${TFS_SRC_DIR}/base64.cpp)
target_link_libraries(boost_test_base64 PRIVATE OpenSSL::Crypto)
