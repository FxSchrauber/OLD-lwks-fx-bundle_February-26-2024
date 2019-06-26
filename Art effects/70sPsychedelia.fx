// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2016-05-11
// @see https://www.lwks.com/media/kunena/attachments/6375/70s_psych_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Contours_7_2016-08-16.png

/**
70s Psychedelia (70sPsychedelia.fx) creates a wide range of contouring effects from your
original image.  Mixing over the original image can be adjusted from 0% to 100%, and the
hue, saturation, and contour pattern can be tweaked.  The contours can also be smudged
by a variable amount.

This is an entirely original effect, but feel free to do what you will with it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 70sPsychedelia.fx
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 2018-07-09 jwrl:
// Removed dependency on pixel size.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 23 December 2018 jwrl.
// Changed filename and subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "70s Psychedelia";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An extreme highly adjustable posterization effect";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Processed : RenderColorTarget;
texture Contours  : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state {
        Texture   = <Input>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Processed = sampler_state {
        Texture   = <Processed>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s_Contours = sampler_state {
        Texture   = <Contours>;
	AddressU  = Mirror;
	AddressV  = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Pattern mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Contouring
<
   string Description = "Contour level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Smudge
<
   string Description = "Smudger";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 ColourOne
<
   string Group = "Colours";
   string Description = "Colour one";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 ColourTwo
<
   string Group = "Colours";
   string Description = "Colour two";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 0.0, 1.0 };

float4 ColourBase
<
   string Group = "Colours";
   string Description = "Base colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float Hue
<
   string Group = "Colours";
   string Description = "Hue";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Saturation
<
   string Group = "Colours";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Monochrome
<
   string Group = "Colours";
   string Description = "Monochrome";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DELTANG_1  25
#define ALIASFIX   50
#define ANGLE_1    0.125664

#define DELTANG_2  29
#define BLURFIX    58
#define ANGLE_2    0.108331

#define LUMA_RED   0.3
#define LUMA_GREEN 0.59
#define LUMA_BLUE  0.11

#define W_SCALE    0.000545

#define EMPTY      0.0.xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_gene (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = EMPTY;

   float2 xy1, xy2;
   float2 xy3 = float2 (1.0, _OutputAspectRatio) * W_SCALE;

   float angle = 0.0;

   for (int i = 0; i < DELTANG_1; i++) {
      sincos (angle, xy2.x, xy2.y);
      xy1 = xy2 * xy3;

      retval += tex2D (s_Input, uv + xy1);
      retval += tex2D (s_Input, uv - xy1);

      angle += ANGLE_1;
   }

   retval /= ALIASFIX;

   float amtC = Contouring + 0.025;
   float Col1 = frac ((0.5 + retval.r + retval.b) * 29.0 * amtC);
   float Col2 = frac ((0.5 + retval.g) * 13.0 * amtC);

   float4 rgb = max (ColourBase, max ((ColourOne * Col1), (ColourTwo * Col2)));
   retval     = (rgb + min (ColourBase, min ((ColourOne * Col1), (ColourTwo * Col2)))) / 2.0;
   retval.a   = Col1 * 0.333333 + Col1 * 0.666667;

   return retval;
}

float4 ps_hueSat (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);
   float4 rgb    = tex2D (s_Processed, uv);

   float luma  = rgb.a;

   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv = float2 (0.0, Cmax).xxyx;

   if (Cmax != 0.0) {
      hsv.y = 1.0 - (Cmin / Cmax);

      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   if (hsv.y != 0.0) {
      float satVal = Saturation + 1.0;

      if (Saturation > 0.0) hsv.y *= satVal;

      hsv.x += Hue / 360.0;

      if (hsv.x > 1.0) hsv.x -= 1.0;

      if (hsv.x < 0.0) hsv.x += 1.0;

      hsv.x *= 6.0;

      int i = (int) floor (hsv.x);

      hsv.x = frac (hsv.x);

      float p = hsv.z * (1.0 - hsv.y);
      float q = hsv.z * (1.0 - hsv.y * hsv.x);
      float r = hsv.z * (1.0 - hsv.y * (1.0 - hsv.x));

      rgb.rgb = (i == 0) ? float3 (hsv.z, r, p) : (i == 1) ? float3 (q, hsv.z, p)
              : (i == 2) ? float3 (p, hsv.z, r) : (i == 3) ? float3 (p, q, hsv.z)
              : (i == 4) ? float3 (r, p, hsv.z) : float3 (hsv.z, p, q);

      float luma1 = (rgb.r * LUMA_RED) + (rgb.g * LUMA_GREEN) + (rgb.b * LUMA_BLUE);

      rgb = lerp (float2 (luma1, 1.0).xxxy, rgb, saturate (satVal));
   }

   retval.rgb = lerp (rgb.rgb, luma.xxx, Monochrome);

   return retval;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd  = tex2D (s_Input, uv);
   float4 pattern = EMPTY;

   float blur  = 1.0 + (Smudge * 5.0);
   float angle = 0.0;

   float2 xy1, xy2;
   float2 xy3 = float2 (1.0, _OutputAspectRatio) * blur * W_SCALE;

   for (int j = 0; j < DELTANG_2; j++) {
      sincos (angle, xy2.x, xy2.y);
      xy1 = xy2 * xy3;

      pattern += tex2D (s_Contours, uv + xy1);
      pattern += tex2D (s_Contours, uv - xy1);

      angle += ANGLE_2;
   }

   pattern /= BLURFIX;

   return lerp (Fgnd, pattern, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Psychedelia
{
   pass P_1
   < string Script = "RenderColorTarget0 = Processed;"; >
   { PixelShader = compile PROFILE ps_gene (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Contours;"; >
   { PixelShader = compile PROFILE ps_hueSat (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
