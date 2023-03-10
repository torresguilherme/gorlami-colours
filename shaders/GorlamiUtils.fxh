#include "GorlamiHeader.fxh"

float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
        float3 Delta = (V - RGB) / C;
        Delta.rgb -= Delta.brg;
        Delta.rgb += float3(2,4,6);
        Delta.brg = step(V, RGB) * Delta.brg;
        float H;
        H = max(Delta.r, max(Delta.g, Delta.b));
        return frac(H / 6);
}

float3 RGBtoHSL(in float3 RGB) {
    float3 HSL = 0;
    float U, V;
    U = -min(RGB.r, min(RGB.g, RGB.b));
    V = max(RGB.r, max(RGB.g, RGB.b));
    HSL.z = ((V - U) * 0.5);
    float C = V + U;
    if (C != 0)
    {
        HSL.x = RGBCVtoHUE(RGB, C, V);
        HSL.y = C / (1 - abs(2 * HSL.z - 1));
    }
    return HSL;
}
    
float3 HUEtoRGB(in float H) 
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R,G,B));
}
    
float3 HSLtoRGB(in float3 HSL)
{
    float3 RGB = HUEtoRGB(HSL.x);
    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
    return (RGB - 0.5) * C + HSL.z;
}

float ScreenSpaceDepth(float2 texcoord) {
    if (iUIUpsideDown) {
        texcoord.y = 1.0 - texcoord.y;
    }

    float depth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord, 0.0, 0.0)).x * depthMultiplier;

    const float c = 0.01;
    if (iUILogarithmic) {
        depth = (exp(depth * log(1.0 + c)) - 1.0) / c;
    }

    if (iUIReversed) {
        depth = 1.0 - depth;
    }

    depth /= farPlane - depth * (farPlane - 1.0);
    return depth;
}

float3 ScreenSpaceNormals(float2 texcoord) {
    float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
    float2 center = texcoord.xy;
    float2 up = center - offset.zy;
    float2 right = center + offset.xz;

    float3 vCenter = float3(center - 0.5, 1) * ScreenSpaceDepth(center);
    float3 vUp = float3(up - 0.5, 1) * ScreenSpaceDepth(up);
    float3 vRight = float3(right = 0.5, 1) * ScreenSpaceDepth(right);

    return normalize(cross(vCenter - vUp, vCenter - vRight)) + 1.0 / 2.0;
}

float3 GeometryNormals(float2 texcoord) {
    return (ScreenSpaceNormals(texcoord).xyz - 0.5) * 2.0;
}

float4 Colours(float2 texcoord) {
    return tex2D(ReShade::BackBuffer, texcoord);
}

float4 InvertColours(float2 texcoord) {
    return float4(1.0, 1.0, 1.0, 1.0) - Colours(texcoord);
}