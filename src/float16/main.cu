#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

#include <iostream>
#include <math.h>
#include <chrono>
#include <cuda_fp16.h> // Include CUDA half precision header

int Width, Height, Channels;
__half* ImageData;
int MinimizationScale = 2;

std::chrono::steady_clock::time_point TsBegin;
std::chrono::steady_clock::time_point TsEnd;

// Kernel function for processing the image
__global__
void applyRelief(__half* input, __half* output, int width, int height, int channels) {
    static int _kernelHeight = 3;
    static int _kernelWidth = 3;
    static int _convCore[3][3] = {
        {-2, -1, 0},
        {-1,  1, 1},
        { 0,  1, 2}
    };

    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x < width && y < height) {
        float rSum = 0, gSum = 0, bSum = 0;
        int weightSum = 0;

        for (int convY = 0; convY < _kernelHeight; convY++) {
            for (int convX = 0; convX < _kernelWidth; convX++) {
                int pixelX = x + (convX - (_kernelWidth / 2));
                int pixelY = y + (convY - (_kernelHeight / 2));

                if (pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height) {
                    rSum += __half2float(input[pixelY * width * channels + pixelX * channels]) * _convCore[convY][convX];
                    gSum += __half2float(input[pixelY * width * channels + pixelX * channels + 1]) * _convCore[convY][convX];
                    bSum += __half2float(input[pixelY * width * channels + pixelX * channels + 2]) * _convCore[convY][convX];
                    weightSum += _convCore[convY][convX];
                }
            }
        }

        // Normalize and clamp the results
        if (weightSum == 0) weightSum = 1;

        rSum /= weightSum;
        gSum /= weightSum;
        bSum /= weightSum;

        output[y * width * channels + x * channels] = __float2half(min(max(rSum, 0.0f), 255.0f));
        output[y * width * channels + x * channels + 1] = __float2half(min(max(gSum, 0.0f), 255.0f));
        output[y * width * channels + x * channels + 2] = __float2half(min(max(bSum, 0.0f), 255.0f));
    }
}

// Kernel function for processing the image
__global__
void applyMinimization(__half* input, __half* output, int width, int height, int channels, int minimizationScale) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    // Calculate the corresponding output pixel location
    int minimX = x / minimizationScale;
    int minimY = y / minimizationScale;
    int minimWidth = width / minimizationScale;
    int minimHeight = height / minimizationScale;

    // Ensure we are within bounds for the output image
    if (minimX < (minimWidth) && minimY < (minimHeight)) {
        float rSum = 0, gSum = 0, bSum = 0;
        int weightSum = 0;

        // Average over a 2x2 block
        for (int minimYOffset = 0; minimYOffset < minimizationScale; minimYOffset++) {
            for (int minimXOffset = 0; minimXOffset < minimizationScale; minimXOffset++) {
                int pixelX = minimX * minimizationScale + minimXOffset;
                int pixelY = minimY * minimizationScale + minimYOffset;

                if (pixelX < width && pixelY < height) {
                    rSum += __half2float(input[pixelY * width * channels + pixelX * channels]);
                    gSum += __half2float(input[pixelY * width * channels + pixelX * channels + 1]);
                    bSum += __half2float(input[pixelY * width * channels + pixelX * channels + 2]);
                    weightSum++;
                }
            }
        }

        // Normalize the sums
        if (weightSum > 0) {
            output[minimY * (minimWidth) * channels + minimX * channels] = __float2half(rSum / weightSum);
            output[minimY * (minimWidth) * channels + minimX * channels + 1] = __float2half(gSum / weightSum);
            output[minimY * (minimWidth) * channels + minimX * channels + 2] = __float2half(bSum / weightSum);
        }
        
    }
}

void loadBmp(const char* filename) {
    unsigned char* stbData = stbi_load(filename, &Width, &Height, &Channels, 3);
    if (!stbData) {
        std::cout << "Failed to load image";
        return;
    }

    // Allocate memory for half precision float
    cudaMallocManaged(&ImageData, Height * Width * Channels * sizeof(__half));
    for (int i = 0; i < Width * Height * Channels; i++) {
        ImageData[i] = __float2half(stbData[i] / 255.0f); // Normalize to [0, 1] and convert to half
    }

    std::cout << "Image: " << filename << "; Width: " << Width << "; Height: " << Height << "; Number of channels: " << Channels << "\n";

    stbi_image_free(stbData);
}
        
int main(int argc, char* argv[]) {
    char* inputFilename = "images/tales.bmp";
    char* outputFilename = "results/tales.bmp";

    if (argc != 3) {
        std::cout << "Usage: app_a.exe {input.bmp} {output.bmp}";
        return EXIT_FAILURE;
    } else {
        inputFilename = argv[1];
        outputFilename = argv[2];
    }

    std::cout << "Started loading image " << std::endl;
    TsBegin = std::chrono::steady_clock::now();

    loadBmp(inputFilename);
    
    TsEnd = std::chrono::steady_clock::now();
    std::cout << "Ended loading image. Time elapsed: " << std::chrono::duration_cast<std::chrono::milliseconds>(TsEnd - TsBegin).count() << " ms" << std::endl;

    int minimizedWidth = Width / MinimizationScale;
    int minimizedHeight = Height / MinimizationScale;

    __half* convPixelArray;
    cudaMallocManaged(&convPixelArray, Height * Width * Channels * sizeof(__half));
    
    __half* resultPixelArray;
    cudaMallocManaged(&resultPixelArray, minimizedHeight * minimizedWidth * Channels * sizeof(__half));
    
    // Define grid and block sizes
    dim3 blockSize(16, 16);
    dim3 gridSize((Width + blockSize.x - 1) / blockSize.x, (Height + blockSize.y - 1) / blockSize.y);

    std::cout << "Started processing " << std::endl;
    TsBegin = std::chrono::steady_clock::now();

    // Launch the kernel to process the image
    applyRelief<<<gridSize, blockSize>>>(ImageData, convPixelArray, Width, Height, Channels);
    cudaDeviceSynchronize();

    // dim3 gridSizeMinim((minimizedWidth + blockSize.x - 1) / blockSize.x, (minimizedHeight + blockSize.y - 1) / blockSize.y);
    applyMinimization<<<gridSize, blockSize>>>(convPixelArray, resultPixelArray, Width, Height, Channels, MinimizationScale);
    cudaDeviceSynchronize();
    
    TsEnd = std::chrono::steady_clock::now();
    std::cout << "Ended processing. Time elapsed: " << std::chrono::duration_cast<std::chrono::milliseconds>(TsEnd - TsBegin).count() << " ms" << std::endl;

    // // Convert __half back to unsigned char for saving
    unsigned char* outputData = new unsigned char[minimizedHeight * minimizedWidth * Channels];
    for (int i = 0; i < minimizedHeight * minimizedWidth * Channels; i++) {
        outputData[i] = static_cast<unsigned char>(min(max(__half2float(resultPixelArray[i]) * 255.0f, 0.0f), 255.0f)); // Convert back to [0, 255]
    }

    // Save the output image using stb_image_write
    stbi_write_bmp(outputFilename, minimizedWidth, minimizedHeight, Channels, outputData);
    std::cout << "File (" << outputFilename << ") saved \n";

    // Clean up
    delete[] outputData;
    cudaFree(ImageData);
    cudaFree(convPixelArray);
    cudaFree(resultPixelArray);

    return EXIT_SUCCESS;
}        
        