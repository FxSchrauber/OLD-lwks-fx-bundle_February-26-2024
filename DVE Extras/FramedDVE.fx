// @Maintainer jwrl
// @Released 2021-09-16
// @Author jwrl
// @Created 2021-09-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Framed_DVE_640.png

/**
 This is a combination of two 2D DVEs designed to provide a drop shadow and vignette
 effect while matching Lightworks' 2D DVE parameters.  Because of the way that the DVEs
 are created and applied they have exactly the same quality impact on the final result
 as a single DVE would.  The main DVE adjusts the foreground, crop, frame and drop shadow.
 When the foreground is cropped it can be given a bevelled textured border.  The bevel
 can be feathered, as can the drop shadow.  The second DVE adjusts the size and position
 of the foreground inside the frame.

 There is actually a third DVE of sorts that adjusts the size and offset of the border
 texture.  This is extremely rudimentary though.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FramedDVE.fx
//
// Version history:
//
// Rebuilt 2021-09-16 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Framed DVE";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Creates a textured frame around the foreground image and resizes and positions the result.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define CropXY(XY, L, R, T, B)  (BadPos (XY.x, L, -R) || BadPos (XY.y, -T, B))

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))
#define GetMirror(SHD,UV,XY) (any (abs (XY - 0.5.xx) > 0.5) \
                             ? EMPTY \
                             : tex2D (SHD, saturate (1.0.xx - abs (1.0.xx - abs (UV)))))

// Definitions used by this shader

#define HALF_PI      1.5707963268
#define PI           3.1415926536

#define BEVEL_SCALE  0.04
#define BORDER_SCALE 0.05

#define SHADOW_DEPTH 0.1
#define SHADOW_SOFT  0.05

#define CENTRE       0.5.xx

#define WHITE        1.0.xxxx
#define EMPTY        0.0.xxxx

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);
DefineInput (Tx, s_RawTx);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (RawTx, s_Texture);
DefineTarget (Mask, s_CropMask);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float DVE_Scale
<
   string Group = "DVE";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float DVE_Z_angle
<
   string Group = "DVE";
   string Description = "Z angle";
   float MinVal = -360.0;
   float MaxVal = 360.0;
> = 0.0;

float DVE_PosX
<
   string Group = "DVE";
   string Description = "X position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float DVE_PosY
<
   string Group = "DVE";
   string Description = "Y position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TLcropX
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float TLcropY
<
   string Description = "Top left crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BRcropX
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float BRcropY
<
   string Description = "Bottom right crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float VideoScale
<
   string Group = "Video insert";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 1.0;

float VideoPosX
<
   string Group = "Video insert";
   string Description = "X position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float VideoPosY
<
   string Group = "Video insert";
   string Description = "Y position";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BorderBevel
<
   string Group = "Border";
   string Description = "Bevel";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float BorderSharpness
<
   string Group = "Border";
   string Description = "Bevel sharpness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float BorderOuter
<
   string Group = "Border";
   string Description = "Outer edge";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.6;

float BorderInner
<
   string Group = "Border";
   string Description = "Inner edge";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.4;

float TexScale
<
   string Group = "Border";
   string Description = "Texture scale";
   float MinVal = 0.5;
   float MaxVal = 2.0;
> = 1.0;

float TexPosX
<
   string Group = "Border";
   string Description = "Texture X";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float TexPosY
<
   string Group = "Border";
   string Description = "Texture Y";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float ShadowOpacity
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float ShadowSoft
<
   string Group = "Shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float ShadowAngle
<
   string Group = "Shadow";
   string Description = "Angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

float ShadowOffset
<
   string Group = "Shadow";
   string Description = "Offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowDistance
<
   string Group = "Shadow";
   string Description = "Distance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool CropToBgd
<
   string Description = "Crop to background";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return BdrPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }
float4 ps_initTx (float2 uv : TEXCOORD3, float2 xy : TEXCOORD4) : COLOR { return GetMirror (s_RawTx, uv, xy); }

float4 ps_crop (float2 uv : TEXCOORD4) : COLOR
{
/* Returned values: crop.w - master crop 
                    crop.x - master border (inside crop) 
                    crop.y - border shading
                    crop.z - drop shadow
*/
   float cropX = TLcropX < BRcropX ? TLcropX : BRcropX;
   float cropY = TLcropY > BRcropY ? TLcropY : BRcropY;

   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 offset = aspect / _OutputWidth;
   float2 xyCrop = float2 (cropX, 1.0 - cropY);
   float2 ccCrop = (xyCrop + float2 (BRcropX, 1.0 - BRcropY)) * 0.5;
   float2 uvCrop = abs (uv - ccCrop);

   xyCrop = abs (xyCrop - ccCrop);

   float2 border = max (0.0.xx, xyCrop - (aspect * BorderWidth * BORDER_SCALE));
   float2 edge_0 = aspect * BorderWidth * BorderBevel * BEVEL_SCALE;
   float2 edge_1 = max (0.0.xx, border + edge_0);

   edge_0 = max (0.0.xx, xyCrop - edge_0);
   edge_0 = (smoothstep (edge_0, xyCrop, uvCrop) + smoothstep (border, edge_1, uvCrop)) - 1.0.xx;
   edge_0 = (clamp (edge_0 * (1.0 + (BorderSharpness * 9.0)), -1.0.xx, 1.0.xx) * 0.5) + 0.5.xx;
   edge_1 = max (0.0.xx, xyCrop - (aspect * ShadowSoft * SHADOW_SOFT));
   edge_1 = smoothstep (edge_1, xyCrop, uvCrop);

   float4 crop = smoothstep (xyCrop - offset, xyCrop + offset, uvCrop).xyxy;

   crop.xy = smoothstep (border - offset, border + offset, uvCrop);
   crop.w = 1.0 - max (crop.w, crop.z);
   crop.x = 1.0 - max (crop.x, crop.y);
   crop.y = max (edge_0.x, edge_0.y);
   crop.z = (1.0 - edge_1.x) * (1.0 - edge_1.y);

   return crop;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv4 : TEXCOORD4) : COLOR
{
   float temp, ShadowX, ShadowY, scale = DVE_Scale < 0.0001 ? 10000.0 : 1.0 / DVE_Scale;

   sincos (radians (ShadowAngle), ShadowY, ShadowX);

   float2 xy0, xy1 = (uv4 - CENTRE) * scale;
   float2 xy2 = float2 (ShadowX, ShadowY * _OutputAspectRatio) * ShadowOffset * SHADOW_DEPTH;
   float2 xy3;

   sincos (radians (DVE_Z_angle), xy0.x, xy0.y);
   temp = (xy0.y * xy1.y) - (xy0.x * xy1.x * _OutputAspectRatio);
   xy1  = float2 ((xy0.x * xy1.y / _OutputAspectRatio) + (xy0.y * xy1.x), temp);

   xy1 += CENTRE - (float2 (DVE_PosX, -DVE_PosY) * 2.0);
   xy3  = xy1;

   float shadow = ShadowDistance * 0.3333333333;

   xy2 += float2 (1.0, 1.0 / _OutputAspectRatio) * shadow * xy2 / max (xy2.x, xy2.y);
   temp = (xy0.y * xy2.y) - (xy0.x * xy2.x * _OutputAspectRatio);
   xy2  = float2 ((xy0.x * xy2.y / _OutputAspectRatio) + (xy0.y * xy2.x), temp);
   xy2  = ((xy1 - xy2 - CENTRE) * (shadow + 1.0) / ((ShadowSoft * 0.05) + 1.0)) + CENTRE;

   float4 Mask = GetPixel (s_CropMask, xy3);

   Mask.z = Overflow (xy2) ? 0.0 : tex2D (s_CropMask, xy2).z;

   scale = VideoScale < 0.0001 ? 10000.0 : 1.0 / VideoScale;
   xy1   = (CENTRE + ((xy1 - CENTRE) * scale)) - (float2 (VideoPosX, -VideoPosY) * 2.0);
   scale = TexScale < 0.0001 ? 10000.0 : 1.0 / TexScale;
   xy3   = (CENTRE + ((xy3 - CENTRE) * scale)) - (float2 (TexPosX, -TexPosY) * 2.0);

   float4 Fgnd = BdrPixel (s_Foreground, xy1);
   float4 Bgnd = GetPixel (s_Background, uv4);
   float4 frame = GetMirror (s_Texture, xy3, uv4);
   float4 retval = lerp (Bgnd, BLACK, Mask.z * ShadowOpacity);

   float alpha_O = ((2.0 * Mask.y) - 1.0);
   float alpha_I = max (0.0, -alpha_O) * abs (BorderInner);

   alpha_O = max (0.0, alpha_O) * abs (BorderOuter);
   frame = BorderOuter > 0.0 ? lerp (frame, WHITE, alpha_O) : lerp (frame, BLACK, alpha_O);
   frame = BorderInner > 0.0 ? lerp (frame, WHITE, alpha_I) : lerp (frame, BLACK, alpha_I);
   retval = lerp (retval, frame, Mask.w);
   retval = lerp (retval, Fgnd, Mask.x);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, retval, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Framed_DVE
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Ptx < string Script = "RenderColorTarget0 = RawTx;"; > ExecuteShader (ps_initTx)
   pass P_1 < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

