include(${TINYREFL_SOURCE_DIR}/cmake/externals.cmake)

find_package(ctti QUIET)
find_package(jsonformoderncpp QUIET)

if(NOT TINYREFL_CTTI_REPO_URL)
    set(TINYREFL_CTTI_REPO_URL https://gitlab.com/Manu343726/ctti.git)
endif()
if(NOT TINYREFL_CTTI_VERSION)
    set(TINYREFL_CTTI_VERSION master)
endif()
if(NOT TINYREFL_JSON_REPO_URL)
    set(TINYREFL_JSON_REPO_URL https://github.com/nlohmann/json.git)
endif()
if(NOT TINYREFL_JSON_VERSION)
    set(TINYREFL_JSON_VERSION v3.1.2)
endif()

set(JSON_BuildTests OFF CACHE BOOL "")

if(NOT TINYREFL_USING_CONAN_TARGETS)
    if(NOT ctti_FOUND)
        external_dependency(ctti ${TINYREFL_CTTI_REPO_URL} ${TINYREFL_CTTI_VERSION})
        add_library(tinyrefl_externals_ctti ALIAS ctti)
    else()
        add_library(tinyrefl_externals_ctti INTERFACE)
        target_link_libraries(tinyrefl_externals_ctti INTERFACE ctti::ctti)
    endif()

    if(NOT jsonformoderncpp_FOUND)
        external_dependency(nlohmann_json ${TINYREFL_JSON_REPO_URL} ${TINYREFL_JSON_VERSION})
        add_library(tinyrefl_externals_jsonformoderncpp ALIAS nlohmann_json)
    else()
        add_library(tinyrefl_externals_jsonformmoderncpp INTERFACE)
        target_link_libraries(tinyrefl_externals_jsonformmoderncpp INTERFACE jsonformmoderncpp::jsonformmoderncpp)
    endif()
else()
    add_library(tinyrefl_externals_ctti INTERFACE)
    target_link_libraries(tinyrefl_externals_ctti INTERFACE CONAN_PKG::ctti)
    add_library(tinyrefl_externals_jsonformoderncpp INTERFACE)
    target_link_libraries(tinyrefl_externals_jsonformoderncpp INTERFACE CONAN_PKG::jsonformoderncpp)
endif()
