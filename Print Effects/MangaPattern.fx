// @Maintainer jwrl
// @Released 2020-11-13
// @Author windsturm
// @Author jwrl
// @Created 2012-05-23
// @see https://www.lwks.com/media/kunena/attachments/6375/FxManga_640.png

/**
 This simulates the star pattern and hard contours used to create tonal values in a Manga
 half-tone image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FxManga.fx
//
// Version history:
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 5 December 2018 jwrl.
// Added creation date.
// Renamed effect.
// Changed subcategory.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Rewrote the code that generates the lookup indexing to be array driven.
// Extended the indexing to be 36 deep instead of the original 32, because for some
// reason Linux got that part wrong and displayed white lines where it overflowed.
// Changed the parameter text to actually mean something.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//
// Converted for ps_2_b compliance by Lightworks user jwrl, 5 February 2016.
//
// Original effect "FxMangaShader" (FxManga.fx) by windsturm.
// Basically as this now stands it's windsturm's algorithm, but with a completely
// different implementation by jwrl (see 3 August 2017, below).  I'm still leaving
// it credited to him on the Lightworks forums, because it is his original approach.
// I appreciate that now it's like the old joke about the original George Washington
// tomahawk with ten new handles and three new heads, but still...
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Manga pattern";
   string Category    = "Stylize";
   string SubCategory = "Print Effects";
   string Notes       = "This simulates the star pattern and hard contours used to create tonal values in a Manga half-tone image";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int skipGS
<
   string Description = "Greyscale derived from:";
   string Enum = "Luminance,RGB average";
> = 0;

float threshold
<
   string Description = "Pattern size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float td1
<
   string Group = "Sample threshold";
   string Description = "Black threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float td2
<
   string Group = "Sample threshold";
   string Description = "Dark grey";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

float td3
<
   string Group = "Sample threshold";
   string Description = "Light grey";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float td4
<
   string Group = "Sample threshold";
   string Description = "White threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 FxMangaShader (float2 xy : TEXCOORD1) : COLOR
{
   float3 d_0 [] = { { 0.44, 0.75, 0.93 }, { 0.15, 0.46, 0.56 }, { 0.84, 0.95, 1.0 },
                     { 0.8,  0.93, 1.0  }, { 0.0,  0.0,  0.12 } };

   int pArray [] = { 0, 1, 0, 2, 3, 2, 1, 4, 1, 3, 5, 3, 0, 1, 0, 2, 3, 2,
                     2, 3, 2, 0, 1, 0, 3, 5, 3, 1, 4, 1, 2, 3, 2, 0, 1, 0 };

   float4 color = tex2D (InputSampler, xy);

   int2 pixXY = fmod (xy * float2 (1.0, 1.0 / _OutputAspectRatio) * _OutputWidth * (1.0 - threshold), 6.0.xx);

   int p = pArray [pixXY.x + (pixXY.y * 6)];

   float4 dots = float4 (d_0 [p], 1.0);

   if (p < 5) {
      float luma = (skipGS == 1) ? (color.r + color.g + color.b) / 3.0 : dot (color.rgb, float3 (0.299, 0.587, 0.114));

      if (luma < td1) return float2 (0.0, 1.0).xxxy;

      if (luma < td2) return dots.xxxw;

      if (luma < td3) return dots.yyyw;

      if (luma <= td4) return dots.zzzw;
   }

   return (1.0).xxxx;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxMangaShader ();
   }
}
