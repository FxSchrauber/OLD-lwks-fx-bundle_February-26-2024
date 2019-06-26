// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Author trirop
// @Created 2016-05-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Fractal1_640.png

/**
Fractal matte 1 produces backgrounds generated from fractal patterns.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FractalMatte1.fx
//
// The fractal generation component was first created by Robert Sch�tze (trirop) in GLSL
// sandbox (http://glslsandbox.com/e#29611.0).  It has been somewhat modified to better
// suit its use in this effect.
//
// Updated by jwrl 22 May 2016 by jwrl.
// Added comprehensive effect colorgrading capability.
//
// LW 14+ version by jwrl 12 February 2017
// SubCategory "Patterns" added.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal matte 1";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Produces fractal patterns for background generation";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture FracOut : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Frac_Sampler = sampler_state
{
   Texture   = <FracOut>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Rate
<
   string Description = "Speed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Description = "Start point";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Size
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointZ";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Mix colour";
   string Group = "Colour";
   bool SupportsAlpha = true;
> = { 0.69, 0.26, 1.0, 1.0 };

float ColourMix
<
   string Description = "Mix level";
   string Group = "Colour";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float HueParam
<
   string Description = "Hue";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float SatParam
<
   string Description = "Saturation";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Description = "Gain";
   string Group = "Luminance";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

float Gamma
<
   string Description = "Gamma";
   string Group = "Luminance";
   float MinVal = 0.0;
   float MaxVal = 4.00;
> = 1.00;

float Brightness
<
   string Description = "Brightness";
   string Group = "Luminance";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Contrast
<
   string Description = "Contrast";
   string Group = "Luminance";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI_2     6.283185

#define INVSQRT3 0.57735

#define R_WEIGHT 0.2989
#define G_WEIGHT 0.5866
#define B_WEIGHT 0.1145

#define SCL_RATE 224

#define LOOP     60

float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fractals (float2 uv : TEXCOORD1) : COLOR
{
   float progress = ((_Progress + StartPoint) * PI_2) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));
   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5;
   float2 xy = uv - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.01), seed.x);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   return float4 (saturate (retval), 1.0);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (InputSampler, uv);
   float4 retval = tex2D (Frac_Sampler, uv);

   float luma   = dot (retval.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));
   float buffer = dot (Colour.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));

   buffer = saturate (buffer - 0.5);
   buffer = 1.0 / (buffer + 0.5);

   float4 temp = Colour * luma * buffer;

   retval = lerp (retval, temp, ColourMix);
   luma   = (retval.r + retval.g + retval.b) / 3.0;

   float RminusG = retval.r - retval.g;
   float RminusB = retval.r - retval.b;
   float GammVal = (Gamma > 1.0) ? Gamma : Gamma * 0.9 + 0.1;
   float Hue_Val = acos ((RminusG + RminusB) / (2.0 * sqrt (RminusG * RminusG + RminusB * (retval.g - retval.b)))) / PI_2;
   float Sat_Val = 1.0 - min (min (retval.r, retval.g), retval.b) / luma;

   if (retval.b > retval.g) Hue_Val = 1.0 - Hue_Val;

   Hue_Val = frac (Hue_Val + (HueParam * 0.5));
   Sat_Val = saturate (Sat_Val * (SatParam + 1.0));

   float Hrange = Hue_Val * 3.0;
   float Hoffst = (2.0 * floor (Hrange) + 1.0) / 6.0;

   buffer = INVSQRT3 * tan ((Hue_Val - Hoffst) * PI_2);
   temp.x = (1.0 - Sat_Val) * luma;
   temp.y = ((3.0 * (buffer + 1.0)) * luma - (3.0 * buffer + 1.0) * temp.x) / 2.0;
   temp.z = 3.0 * luma - temp.y - temp.x;

   retval = (Hrange < 1.0) ? temp.zyxw : (Hrange < 2.0) ? temp.xzyw : temp.yxzw;
   temp   = (((pow (retval, 1.0 / GammVal) * Gain) + Brightness.xxxx - 0.5.xxxx) * Contrast) + 0.5.xxxx;
   retval = lerp (Fgd, temp, Opacity);

   retval.a = Fgd.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FractalMatte1
{
   pass Pass_one
   <
      string Script = "RenderColorTarget0 = FracOut;";
   >
   {
      PixelShader = compile PROFILE ps_fractals ();
   }

   pass Pass_two
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
