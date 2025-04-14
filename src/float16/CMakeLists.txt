project(app_a_cuda CUDA)

set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_ARCHITECTURES "native")
add_executable(image_process_float16 main.cu)

target_include_directories(image_process_float16 PUBLIC ../../vendor/)

set_target_properties(
        image_process_float16
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)