cmake_minimum_required(VERSION 3.10.0)
project(lab_4 VERSION 0.1.0 LANGUAGES C CXX)


set(OSBitness 32)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(OSBitness 64)
endif()
set (FullOutputDir "${CMAKE_SOURCE_DIR}/bin/${CMAKE_SYSTEM_NAME}${OSBitness}/${CMAKE_BUILD_TYPE}")
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY "${FullOutputDir}")

add_subdirectory(src/float16)
add_subdirectory(src/unsigned_char)
