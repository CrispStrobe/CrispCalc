cmake_minimum_required(VERSION 3.15)
project(cas_wrapper)

set(CMAKE_CXX_STANDARD 14)  # SymEngine C++ API needs C++14
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set Homebrew prefix
set(HOMEBREW_PREFIX "/opt/homebrew")
if(NOT EXISTS ${HOMEBREW_PREFIX})
    set(HOMEBREW_PREFIX "/usr/local") # Intel Mac fallback
endif()

# Find include directories
find_path(SYMENGINE_INCLUDE_DIR 
    NAMES symengine/cwrapper.h
    PATHS ${HOMEBREW_PREFIX}/include
    NO_DEFAULT_PATH
)

find_path(GMP_INCLUDE_DIR 
    NAMES gmp.h
    PATHS ${HOMEBREW_PREFIX}/include
    NO_DEFAULT_PATH
)

# Find libraries
find_library(SYMENGINE_LIBRARY 
    NAMES symengine
    PATHS ${HOMEBREW_PREFIX}/lib
    NO_DEFAULT_PATH
)

find_library(GMP_LIBRARY 
    NAMES gmp
    PATHS ${HOMEBREW_PREFIX}/lib
    NO_DEFAULT_PATH
)

# Check if all dependencies were found
if(NOT SYMENGINE_INCLUDE_DIR)
    message(FATAL_ERROR "SymEngine headers not found. Install with: brew install symengine")
endif()

if(NOT GMP_INCLUDE_DIR)
    message(FATAL_ERROR "GMP headers not found. Install with: brew install gmp")
endif()

if(NOT SYMENGINE_LIBRARY)
    message(FATAL_ERROR "SymEngine library not found. Install with: brew install symengine")
endif()

if(NOT GMP_LIBRARY)
    message(FATAL_ERROR "GMP library not found. Install with: brew install gmp")
endif()

# Print what we found
message(STATUS "SymEngine include: ${SYMENGINE_INCLUDE_DIR}")
message(STATUS "SymEngine library: ${SYMENGINE_LIBRARY}")
message(STATUS "GMP include: ${GMP_INCLUDE_DIR}")
message(STATUS "GMP library: ${GMP_LIBRARY}")

# Create the shared library
add_library(cas_wrapper SHARED cas_wrapper.cpp)

# Set include directories
target_include_directories(cas_wrapper PRIVATE 
    ${SYMENGINE_INCLUDE_DIR}
    ${GMP_INCLUDE_DIR}
)

# Link libraries
target_link_libraries(cas_wrapper PRIVATE 
    ${SYMENGINE_LIBRARY}
    ${GMP_LIBRARY}
)

# Set properties
set_target_properties(cas_wrapper PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# macOS specific settings
if(APPLE)
    set_target_properties(cas_wrapper PROPERTIES
        INSTALL_NAME_DIR "@rpath"
        BUILD_WITH_INSTALL_RPATH TRUE
    )
endif()