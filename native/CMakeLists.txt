cmake_minimum_required(VERSION 3.15)
project(cas_wrapper)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Find Dependencies from Homebrew ---
set(HOMEBREW_PREFIX "/opt/homebrew")
if(NOT EXISTS ${HOMEBREW_PREFIX})
    set(HOMEBREW_PREFIX "/usr/local")
endif()

# Find include directories
find_path(SYMENGINE_INCLUDE_DIR NAMES symengine/cwrapper.h PATHS ${HOMEBREW_PREFIX}/include REQUIRED)
find_path(GMP_INCLUDE_DIR NAMES gmp.h PATHS ${HOMEBREW_PREFIX}/include REQUIRED)

# --- Find a mix of STATIC and DYNAMIC libraries ---
# We will link these statically as they are available as .a files
find_library(SYMENGINE_STATIC_LIB NAMES libsymengine.a PATHS ${HOMEBREW_PREFIX}/lib REQUIRED)
find_library(GMP_STATIC_LIB NAMES libgmp.a PATHS ${HOMEBREW_PREFIX}/lib REQUIRED)
find_library(MPFR_STATIC_LIB NAMES libmpfr.a PATHS ${HOMEBREW_PREFIX}/lib REQUIRED)
find_library(MPC_STATIC_LIB NAMES libmpc.a PATHS ${HOMEBREW_PREFIX}/lib REQUIRED)

# FLINT is only available as a dynamic library, so we find that instead.
find_library(FLINT_DYLIB NAMES libflint.dylib PATHS ${HOMEBREW_PREFIX}/lib REQUIRED)

message(STATUS "✅ Using static SymEngine: ${SYMENGINE_STATIC_LIB}")
message(STATUS "✅ Using dynamic FLINT: ${FLINT_DYLIB}")

# --- Build the Shared Library ---
add_library(cas_wrapper SHARED cas_wrapper.cpp)

target_include_directories(cas_wrapper PRIVATE ${SYMENGINE_INCLUDE_DIR} ${GMP_INCLUDE_DIR})

# Link all libraries
target_link_libraries(cas_wrapper PRIVATE
    ${SYMENGINE_STATIC_LIB}  # Highest-level library first
    ${FLINT_DYLIB}           # A dependency of SymEngine
    ${MPC_STATIC_LIB}        # A dependency of SymEngine
    ${MPFR_STATIC_LIB}       # A dependency of MPC
    ${GMP_STATIC_LIB}        # A dependency of MPFR
)

# --- Target Properties ---
set_target_properties(cas_wrapper PROPERTIES CXX_VISIBILITY_PRESET hidden)
if(APPLE)
    set_target_properties(cas_wrapper PROPERTIES INSTALL_NAME_DIR "@rpath")
endif()

# Post-build check
add_custom_command(TARGET cas_wrapper POST_BUILD
    COMMAND otool -L $<TARGET_FILE:cas_wrapper>
    COMMENT "✅ Verifying library dependencies..."
    VERBATIM
)