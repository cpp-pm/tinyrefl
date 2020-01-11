if(HUNTER_ENABLED)
    hunter_add_package(fmt)
    find_package(fmt CONFIG REQUIRED)

    hunter_add_package(cppfs)
    find_package(cppfs CONFIG REQUIRED)

    hunter_add_package(cppast)
    find_package(cppast CONFIG REQUIRED)

    hunter_add_package(LLVM)
    find_package(LLVM CONFIG REQUIRED)

    include_directories(${LLVM_INCLUDE_DIRS})
    add_definitions(${LLVM_DEFINITIONS})
    llvm_map_components_to_libnames(llvm_libs support core) # How we can compile only libclang?

    add_library(tinyrefl_externals_fmt          INTERFACE)
    add_library(tinyrefl_externals_cppfs        INTERFACE)
    add_library(tinyrefl_externals_cppast       INTERFACE)
    add_library(tinyrefl_externals_llvm_support INTERFACE)

    target_link_libraries(tinyrefl_externals_fmt          INTERFACE fmt::fmt)
    target_link_libraries(tinyrefl_externals_cppast       INTERFACE cppast::cppast)
    target_link_libraries(tinyrefl_externals_cppfs        INTERFACE cppfs::cppfs)
    target_link_libraries(tinyrefl_externals_llvm_support INTERFACE LLVMSupport)

else()
    include(${TINYREFL_SOURCE_DIR}/cmake/utils.cmake)
    include(${TINYREFL_SOURCE_DIR}/cmake/externals.cmake)

    set(CPPAST_BUILD_EXAMPLE OFF CACHE BOOL "disable cppast examples")
    set(CPPAST_BUILD_TEST OFF CACHE BOOL "disable cppast tests")
    set(CPPAST_BUILD_TOOL OFF CACHE BOOL "disable cppast tool")
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "build cppfs as static lib")
    set(OPTION_BUILD_TESTS OFF CACHE BOOL "disable cppfs tests")

    if(NOT ("${TINYREFL_LLVM_VERSION}" STREQUAL "${TINYREFL_LLVM_VERSION_MAJOR}.${TINYREFL_LLVM_VERSION_MINOR}.${TINYREFL_LLVM_VERSION_FIX}"))
        message(FATAL_ERROR "WTF????")
    endif()

    if(NOT TINYREFL_FMT_REPO_URL)
        set(TINYREFL_FMT_REPO_URL https://github.com/fmtlib/fmt.git)
    endif()
    if(NOT TINYREFL_FMT_VERSION)
        set(TINYREFL_FMT_VERSION 5.1.0)
    endif()
    if(NOT TINYREFL_CPPAST_REPO_URL)
        set(TINYREFL_CPPAST_REPO_URL https://github.com/Manu343726/cppast.git)
    endif()
    if(NOT TINYREFL_CPPAST_VERSION)
        set(TINYREFL_CPPAST_VERSION master)
    endif()
    if(NOT TINYREFL_CPPFS_REPO_URL)
        set(TINYREFL_CPPFS_REPO_URL https://github.com/Manu343726/cppfs.git)
    endif()
    if(NOT TINYREFL_CPPFS_VERSION)
        set(TINYREFL_CPPFS_VERSION optional_libSSL2)
    endif()

    if(TINYREFL_USING_CONAN_TARGETS)
        add_library(tinyrefl_externals_fmt          INTERFACE)
        add_library(tinyrefl_externals_cppast       INTERFACE)
        add_library(tinyrefl_externals_llvm_support INTERFACE)

        target_link_libraries(tinyrefl_externals_fmt          INTERFACE CONAN_PKG::fmt)
        target_link_libraries(tinyrefl_externals_cppast       INTERFACE CONAN_PKG::cppast)
        target_link_libraries(tinyrefl_externals_llvm_support INTERFACE CONAN_PKG::llvm_support)

        # TODO: Create conan recipe for cppfs
        external_dependency(cppfs ${TINYREFL_CPPFS_REPO_URL} ${TINYREFL_CPPFS_VERSION})
        add_library(tinyrefl_externals_cppfs ALIAS cppfs)
    else()
        find_package(fmt)
        find_package(cppast)
        find_package(llvm_support)
        find_package(cppfs)

        if(NOT fmt_FOUND)
            external_dependency(fmt-header-only ${TINYREFL_FMT_REPO_URL} ${TINYREFL_FMT_VERSION})

            # Here we cannot define an ALIAS library since fmt::fmt-header-only itself is
            # already an alias
            add_library(tinyrefl_externals_fmt INTERFACE)
            target_link_libraries(tinyrefl_externals_fmt INTERFACE fmt::fmt-header-only)
        else()
            add_library(tinyrefl_externals_fmt INTERFACE)
            target_link_libraries(tinyrefl_externals_fmt INTERFACE fmt::fmt)
        endif()

        if(NOT cppast_FOUND OR NOT llvm_support_FOUND)
            if(TINYREFL_USE_LOCAL_LLVM)
                # Find local llvm-config tool for cppast setup
                find_program(llvm-config NAMES llvm-config llvm-config-${TINYREFL_LLVM_VERSION_MAJOR}.${TINYREFL_LLVM_VERSION_MINOR})

                if(llvm-config)
                    execute_process(COMMAND ${llvm-config} --version
                        OUTPUT_VARIABLE llvm-config-version OUTPUT_STRIP_TRAILING_WHITESPACE)

                    if(llvm-config-version VERSION_EQUAL TINYREFL_LLVM_VERSION)
                        set(LLVM_CONFIG_BINARY "${llvm-config}")
                        message(STATUS "Using local LLVM ${TINYREFL_LLVM_VERSION} install")
                    else()
                        message(FATAL_ERROR "Wrong LLVM install found. Found llvm-config ${llvm-config-version}, required ${TINYREFL_LLVM_VERSION}")
                    endif()
                else()
                    message(FATAL_ERROR "TINYREFL_USE_LOCAL_LLVM set and llvm-config program not found")
                endif()
            else()
                # Download precompiled LLVM release
                if(NOT TINYREFL_LLVM_DOWNLOAD_URL)
                    if(TINYREFL_LLVM_DOWNLOAD_FROM_OFFICIAL_SERVER)
                        message(STATUS "Using default LLVM download url from LLVM official servers")

                        if(TINYREFL_LLVM_VERSION_MAJOR EQUAL 5)
                            set(TINYREFL_LLVM_DOWNLOAD_URL "http://releases.llvm.org/${TINYREFL_LLVM_VERSION}/clang+llvm-${TINYREFL_LLVM_VERSION}-linux-x86_64-ubuntu14.04.tar.xz")
                        else()
                            set(TINYREFL_LLVM_DOWNLOAD_URL "http://releases.llvm.org/${TINYREFL_LLVM_VERSION}/clang+llvm-${TINYREFL_LLVM_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz")
                        endif()
                    else()
                        message(STATUS "Using default LLVM download url from bintray")
                        set(TINYREFL_LLVM_DOWNLOAD_URL "https://dl.bintray.com/manu343726/llvm-releases/clang+llvm-${TINYREFL_LLVM_VERSION}-x86_64-linux-gnu-ubuntu-14.04.tar.xz")
                    endif()
                else()
                    message(STATUS "Using custom LLVM download url: ${TINYREFL_LLVM_DOWNLOAD_URL}")
                endif()

                # LLVM releases are compiled with old GCC ABI
                add_definitions(-D_GLIBCXX_USE_CXX11_ABI=0)
                # Force cppast to be compiled with old GCC ABI
                set(CPPAST_USE_OLD_LIBSTDCPP_ABI ON CACHE INTERNAL "")

                set(LLVM_DOWNLOAD_URL "${TINYREFL_LLVM_DOWNLOAD_URL}")
                message(STATUS "Using LLVM download URL: ${TINYREFL_LLVM_DOWNLOAD_URL}")
            endif()

            external_dependency(cppast ${TINYREFL_CPPAST_REPO_URL} ${TINYREFL_CPPAST_VERSION})
            add_library(tinyrefl_externals_cppast ALIAS cppast)

            if(NOT LLVM_CONFIG_BINARY)
                message(FATAL_ERROR "llvm-config binary not set")
            else()
                message(STATUS "llvm-config binary: ${LLVM_CONFIG_BINARY}")
            endif()

            execute_process(COMMAND ${LLVM_CONFIG_BINARY} --libdir OUTPUT_VARIABLE stdout)
            string(STRIP "${stdout}" stdout)
            set(LLVM_CMAKE_PATH "${stdout}/cmake/llvm" CACHE PATH "")
            set(CLANG_CMAKE_PATH "${stdout}/cmake/clang" CACHE PATH "")
            set(TINYREFL_TOOL_BUILDING_CPPAST_FROM_SOURCES TRUE)

            message(STATUS "llvm cmake path: ${LLVM_CMAKE_PATH}")
            message(STATUS "clang cmake path: ${CLANG_CMAKE_PATH}")

            find_package(LLVM ${TINYREFL_LLVM_VERSION} REQUIRED EXACT CONFIG PATHS "${LLVM_CMAKE_PATH}" NO_DEFAULT_PATH)
            add_library(tinyrefl_externals_llvm_support INTERFACE)
            target_link_libraries(tinyrefl_externals_llvm_support INTERFACE LLVMSupport)
        else()
            add_library(tinyrefl_externals_cppast INTERFACE)
            target_link_libraries(tinyrefl_externals_cppast INTERFACE cppast::cppast)
        endif()

        if(NOT cppfs_FOUND)
            external_dependency(cppfs ${TINYREFL_CPPFS_REPO_URL} ${TINYREFL_CPPFS_VERSION})
            add_library(tinyrefl_externals_cppfs ALIAS cppfs)
        else()
            add_library(tinyrefl_externals_cppfs INTERFACE)
            target_link_libraries(tinyrefl_externals_cppfs INTERFACE cppfs::cppfs)
        endif()
    endif()
endif()

function(define_llvm_version_variables TARGET)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION STRING)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_MAJOR)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_MINOR)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_FIX)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_MAJOR SUFFIX _STRING STRING)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_MINOR SUFFIX _STRING STRING)
    add_variable_compile_definition(${TARGET} TINYREFL_LLVM_VERSION_FIX SUFFIX _STRING STRING)
endfunction()
