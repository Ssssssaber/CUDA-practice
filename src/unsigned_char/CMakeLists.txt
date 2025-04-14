project(image_process_uchar CUDA)

set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_ARCHITECTURES "native")
add_executable(image_process_uchar main.cu)

target_include_directories(image_process_uchar PUBLIC ../../vendor/)

set_target_properties(
        image_process_uchar
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)