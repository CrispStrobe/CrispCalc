cmake_minimum_required(VERSION 3.15)
project(cas_wrapper)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Find Dependencies from Homebrew ---
set(HOMEBREW_PREFIX "/opt/homebrew")
if(NOT EXISTS ${HOMEBREW_PREFIX})
    set(HOMEBREW_PREFIX "/usr/local")
endif()

find_path(SYMENGINE_INCLUDE_DIR NAMES symengine/cwrapper.h PATHS ${HOMEBREW_PREFIX}/include REQUIRED)
find_path(GMP_INCLUDE_DIR NAMES gmp.h PATHS ${HOMEBREW_PREFIX}/include REQUIRED)

# FIX: Change from finding a static library (.a) to the dynamic library (.dylib)
# that Homebrew provides. This is the root cause of the linker errors.
find_library(SYMENGINE_LIB NAMES libsymengine.dylib PATHS ${HOMEBREW_PREFIX}/lib NO_DEFAULT_PATH REQUIRED)

# We still link the other dependencies statically where possible
find_library(GMP_STATIC_LIB NAMES libgmp.a PATHS ${HOMEBREW_PREFIX}/lib NO_DEFAULT_PATH REQUIRED)
find_library(MPFR_STATIC_LIB NAMES libmpfr.a PATHS ${HOMEBREW_PREFIX}/lib NO_DEFAULT_PATH REQUIRED)
find_library(MPC_STATIC_LIB NAMES libmpc.a PATHS ${HOMEBREW_PREFIX}/lib NO_DEFAULT_PATH REQUIRED)
find_library(FLINT_DYLIB NAMES libflint.dylib PATHS ${HOMEBREW_PREFIX}/lib NO_DEFAULT_PATH REQUIRED)

message(STATUS "✅ Using SymEngine Library: ${SYMENGINE_LIB}")
message(STATUS "✅ Using dynamic FLINT: ${FLINT_DYLIB}")

# --- Build the Shared Library ---
add_library(cas_wrapper SHARED cas_wrapper.cpp)

target_compile_definitions(cas_wrapper PUBLIC HAVE_SYMENGINE_FLINT)
target_include_directories(cas_wrapper PRIVATE ${SYMENGINE_INCLUDE_DIR} ${GMP_INCLUDE_DIR})

# Link all libraries, now using the correct SymEngine library
target_link_libraries(cas_wrapper PRIVATE
    ${SYMENGINE_LIB}         # Use the dynamic library we found
    ${FLINT_DYLIB}
    ${MPC_STATIC_LIB}
    ${MPFR_STATIC_LIB}
    ${GMP_STATIC_LIB}
)

# --- Target Properties ---
set_target_properties(cas_wrapper PROPERTIES CXX_VISIBILITY_PRESET hidden)
if(APPLE)
    set_target_properties(cas_wrapper PROPERTIES INSTALL_NAME_DIR "@rpath")
endif()

add_custom_command(TARGET cas_wrapper POST_BUILD
    COMMAND otool -L $<TARGET_FILE:cas_wrapper>
    COMMENT "✅ Verifying library dependencies..."
    VERBATIM
)