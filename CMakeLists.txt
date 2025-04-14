cmake_minimum_required(VERSION 3.10.0)
project(lab_4 VERSION 0.1.0 LANGUAGES C CXX)


set(OSBitness 32)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(OSBitness 64)
endif()

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  message(FATAL_ERROR "---- Clang not supported -----")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    message("---- Using GCC -----")
    set (FULL_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/bin/${CMAKE_SYSTEM_NAME}${OSBitness}/${CMAKE_BUILD_TYPE}")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
    message(FATAL_ERROR "---- Intel compiler not supported -----")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    message("---- Using MSVC -----")
    set (FULL_OUTPUT_DIR "${CMAKE_SOURCE_DIR}/bin/${CMAKE_SYSTEM_NAME}${OSBitness}/")
endif()

set (CMAKE_LIBRARY_OUTPUT_DIRECTORY "${FULL_OUTPUT_DIR}")
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY "${FULL_OUTPUT_DIR}")

add_subdirectory(src/float16)
add_subdirectory(src/unsigned_char)
