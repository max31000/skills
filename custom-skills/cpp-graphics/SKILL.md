---
name: cpp-graphics
description: >
  C++ and computer graphics programming. Use when working with C++, Vulkan,
  OpenGL, ray tracing, path tracing, shaders, GLSL, HLSL, or mentions
  "Vulkan", "ray tracing", "path tracing", "shader", "GLSL", "HLSL",
  "BVH", "graphics programming", "rasterization", "PBR", "BRDF",
  "C++ graphics", "compute shader".
---

# C++ & Computer Graphics

Assist with modern C++ and GPU graphics programming: Vulkan, shaders, ray tracing.

## Modern C++ (C++17/20)

### Resource Management
- RAII for all GPU handles — wrap VkBuffer, VkImage etc. in structs with destructors.
- Prefer `std::unique_ptr` / `std::shared_ptr` over raw `new`/`delete`.
- Use `[[nodiscard]]` on functions returning error codes or handles.
- `std::span<T>` for non-owning array views (C++20). Avoid raw pointer + size pairs.

### Performance Patterns
- Avoid `virtual` dispatch in hot paths — prefer templates or `std::variant`.
- Data-oriented design: structure of arrays (SoA) over array of structs (AoS) for cache efficiency.
- Use `alignas(16)` or `alignas(64)` for SIMD-friendly data.
- Profile before optimizing: `perf`, Intel VTune, NVIDIA Nsight.

## Vulkan

### Initialization Order
1. VkInstance -> VkPhysicalDevice -> VkDevice -> VkQueue
2. VkSurface -> VkSwapchain -> VkImageViews
3. VkRenderPass -> VkFramebuffer (or dynamic rendering in 1.3+)
4. VkDescriptorSetLayout -> VkPipelineLayout -> VkPipeline
5. VkCommandPool -> VkCommandBuffer
6. VkSemaphore / VkFence for frame synchronization

### RAII Pattern
```cpp
struct Buffer {
    VkDevice       device     = VK_NULL_HANDLE;
    VkBuffer       buffer     = VK_NULL_HANDLE;
    VmaAllocation  allocation = nullptr;

    Buffer() = default;
    Buffer(const Buffer&) = delete;
    Buffer(Buffer&& o) noexcept
        : device(o.device), buffer(o.buffer), allocation(o.allocation)
    { o.buffer = VK_NULL_HANDLE; }

    ~Buffer() {
        if (buffer != VK_NULL_HANDLE)
            vmaDestroyBuffer(g_allocator, buffer, allocation);
    }
};
```

### Validation Layers
```cpp
#ifdef NDEBUG
constexpr bool kEnableValidation = false;
#else
constexpr bool kEnableValidation = true;
#endif
// Always enable in debug. Never ship with validation on.
```

### Synchronization
- Use pipeline barriers for image layout transitions — stage and access masks must be correct.
- Prefer timeline semaphores (Vulkan 1.2+) over binary semaphores for complex multi-queue work.
- `VK_PIPELINE_STAGE_2_*` flags (synchronization2 extension) are cleaner — prefer them.
- Frame-in-flight pattern: N command buffers + N sets of semaphores (typically N=2 or 3).

## GLSL Shaders

### Vertex Shader
```glsl
#version 460

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inNormal;
layout(location = 2) in vec2 inTexCoord;

layout(set = 0, binding = 0) uniform CameraUBO {
    mat4 view;
    mat4 proj;
    vec3 cameraPos;
} camera;

layout(push_constant) uniform PushConstants {
    mat4 model;
} pc;

layout(location = 0) out vec3 outWorldPos;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec2 outTexCoord;

void main() {
    vec4 worldPos = pc.model * vec4(inPosition, 1.0);
    outWorldPos   = worldPos.xyz;
    outNormal     = mat3(transpose(inverse(pc.model))) * inNormal;
    outTexCoord   = inTexCoord;
    gl_Position   = camera.proj * camera.view * worldPos;
}
```

### Numeric Precision
- Use `highp` for positions and normals; `mediump` only for color output.
- Avoid catastrophic cancellation when a is approximately equal to b — reformulate.
- Clamp NaN-prone operations: `max(dot(n, l), 0.0)` not `dot(n, l)`.

## Ray Tracing & Path Tracing

### Core Data Structures
```cpp
struct Ray {
    glm::vec3 origin;
    glm::vec3 direction;  // normalized
    float tMin = 1e-4f;   // avoid self-intersection
    float tMax = 1e30f;
};

struct HitRecord {
    glm::vec3 point;
    glm::vec3 normal;     // always outward-facing after setFaceNormal
    float     t;
    bool      frontFace;
    Material* material = nullptr;

    void setFaceNormal(const Ray& r, const glm::vec3& outwardNormal) {
        frontFace = glm::dot(r.direction, outwardNormal) < 0.0f;
        normal    = frontFace ? outwardNormal : -outwardNormal;
    }
};
```

### BVH (Bounding Volume Hierarchy)
- Build: sort primitives by centroid along the longest AABB axis, split at median.
  SAH (Surface Area Heuristic) gives better quality at the cost of build time.
- Traverse: test both children when ray hits parent AABB; visit nearest child first.
- Leaf size: 1-4 primitives per leaf depending on intersection cost.
- Storage: flatten tree to array in DFS order for cache-friendly traversal.

### Path Tracing Estimator
```
L(x, wo) = Le(x, wo) + integral[ fr(x, wi, wo) * Li(x, wi) * |cos(theta_i)| ] dwi

Monte Carlo estimate:
L ~= (1/N) * sum[ fr(wi) * Li(wi) * |cos(theta_i)| / pdf(wi) ]
```
- Russian Roulette: terminate paths with probability (1 - throughput). Divide surviving paths by survival probability.
- Next Event Estimation (NEE): explicitly sample lights + combine with BRDF sample via MIS.
- Importance sampling: sample BRDF lobe, not uniform hemisphere. For GGX use VNDF sampling.

### PBR / BRDF
- Lambertian diffuse: `fr = albedo / PI`
- GGX specular: `fr = (D * G * F) / (4 * NdotL * NdotV)`
  - D = GGX/Trowbridge-Reitz normal distribution function
  - G = Smith correlated masking-shadowing
  - F = Schlick Fresnel approximation
- Energy conservation: `diffuse_weight = (1 - metallic) * (1 - F)`.
- Use the metallic-roughness workflow (UE4/glTF standard).

## Math Utilities
```cpp
// Orthonormal basis from a normal vector (Pixar ONB, numerically stable)
void buildONB(const glm::vec3& n, glm::vec3& t, glm::vec3& b) {
    float sign = std::copysign(1.0f, n.z);
    float a    = -1.0f / (sign + n.z);
    float c    = n.x * n.y * a;
    t = glm::vec3(1.0f + sign * n.x * n.x * a,  sign * c,        -sign * n.x);
    b = glm::vec3(c,                              sign + n.y*n.y*a, -n.y);
}

// Cosine-weighted hemisphere sample (Malley method)
glm::vec3 cosineSampleHemisphere(float u1, float u2) {
    float r   = std::sqrt(u1);
    float phi = 2.0f * glm::pi<float>() * u2;
    return { r * std::cos(phi), r * std::sin(phi), std::sqrt(1.0f - u1) };
}

// Low-discrepancy sequence: Halton
float halton(int index, int base) {
    float result = 0.0f, f = 1.0f;
    while (index > 0) { f /= base; result += f * (index % base); index /= base; }
    return result;
}
```
