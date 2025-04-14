# About
Laboratory projects for parallel image processing using CUDA.

# Build from source

The result bin path is 'bin/{System name}{OS bitness}/{Build type}'.
Example:
* System: Windows
* Bitness: 64
* Type: Release <br>
Result build path is 'bin/Windows64/Release/'

#### Windows
```console
git clone https://github.com/Ssssssaber/CUDA-practice
cd CUDA-practice/
./build-release.bat
```
#### Linux
```console
git clone https://github.com/Ssssssaber/CUDA-practice
cd CUDA-practice/
./build-release.sh
```

# Usage
#### image_process_uchar
Relief and minimization
```console
image_process_uchar {input.bmp} {output.bmp}
```
#### image_process_float16
The same app but uses float16 instead of uchar
```console
image_process_float16 {input.bmp} {output.bmp}