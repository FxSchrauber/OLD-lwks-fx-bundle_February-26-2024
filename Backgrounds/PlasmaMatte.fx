// @Maintainer jwrl
// @Released 2021-09-04
// @Author jwrl
// @Created 2021-09-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma.mp4

/**
 This effect generates soft plasma-like cloud patterns.  Hue, level, saturation, and rate
 of change of the pattern are all adjustable, and the pattern is also adjustable.  Because
 this background is newly created  media it will be produced at the sequence resolution.
 This means that any background video will also be locked to that resolution.

 NOTE: Backgrounds are newly created media and are produced at the sequence resolution.
 They are then cropped to the background resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PlasmaMatte.fx
//
// Version history:
//
// Rewrite 2021-09-04 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Plasma matte";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Generates soft plasma clouds";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define RGB_LUMA float3(0.2989, 0.5866, 0.1145)

#define TWO_PI   6.2831853072
#define HALF_PI  1.5707963268

float _Progress;
float _LengthFrames;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Input and target
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Rate
<
   string Description = "Rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Style
<
   string Description = "Pattern style";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Gain
<
   string Description = "Pattern gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Level
<
   string Description = "Level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6666666667;

float Hue
<
   string Description = "Hue";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv0 : TEXCOORD, float2 uv1 : TEXCOORD1) : COLOR
{
   float4 Bgnd = GetPixel (s_Input, uv1);

   float2 xy = uv0;

   if (_OutputAspectRatio <= 1.0) {
      xy.x = (xy.x - 0.5) * _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) {
         xy.y -= 0.5;
         xy   *= _OutputAspectRatio;
         xy.y += 0.5;
      }

      xy.x += 0.5;
   }
   else {
      xy.y = (xy.y - 0.5) / _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) {
         xy.x -= 0.5;
         xy   /= _OutputAspectRatio;
         xy.x += 0.5;
      }

      xy.y += 0.5;
   }

   float rate = _LengthFrames * _Progress / (1.0 + (Rate * 38.0));

   float2 xy1, xy2, xy3, xy4 = (xy - 0.5.xx) * HALF_PI;

   sincos (xy4, xy3, xy2.yx);

   xy1  = lerp (xy3, xy2, (1.0 + Style) * 0.5) * (5.5 - (Scale * 5.0));
   xy1 += sin (xy1 * HALF_PI + rate.xx).yx;
   xy4  = xy1 * HALF_PI;

   sincos (xy1.x, xy3.x, xy3.y);
   sincos (xy4.x, xy2.x, xy2.y);
   sincos (xy1.y, xy1.x, xy1.y);
   sincos (xy4.y, xy4.x, xy4.y);

   float3 ptrn = (dot (xy2, xy4.xx) + dot (xy1, xy3.yy)).xxx;

   ptrn.y = dot (xy1, xy2.xx) + dot (xy3, xy4.xx);
   ptrn.z = dot (xy2, xy3.yy) + dot (xy1, xy4.yy);
   ptrn  += float3 (Hue, 0.5, 1.0 - Hue) * TWO_PI;

   float3 retval = sin (ptrn) * ((Gain * 0.5) + 0.05);

   retval = saturate (retval + Level.xxx);

   float luma = dot (retval, RGB_LUMA);

   retval = lerp (luma.xxx, retval, Saturation * 2.0);

   return lerp (Bgnd, float4 (retval, 1.0), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PlasmaMatte
{
   pass P_1 ExecuteShader (ps_main)
}

