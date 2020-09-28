// @Maintainer jwrl
// @Released 2020-09-28
// @Author khaver
// @Created 2011-04-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Tiles_640.png

/**
 Tiles breaks the image up into adjustable tiles of solid colour.  It's like a mosaic
 effect but has adjustable bevelled edges as well.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TilesFx.fx
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which could cause the effect to not behave as
// expected on Linux and Mac systems.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiles";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Breaks the image up into adjustable solid colour tiles with bevelled edges";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and shaders
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state {
   Texture = <Input>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Size
<
   string Description = "Size";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.05; // Default value

float Threshhold
<
   string Description = "Edge Width";
   float MinVal       = 0.0;
   float MaxVal       = 2.0;
> = 0.15; // Default value

float4 EdgeColor
<
   string Description = "Color";
   bool SupportsAlpha = false;
> = { 0.7, 0.7, 0.7, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 tilesPS (float2 xy : TEXCOORD1) : COLOR
{
   if (Size <= 0.0) return tex2D (FgSampler, xy);

   float threshholdB =  1.0 - Threshhold;

   float2 Pbase = xy - fmod (xy, Size.xx);
   float2 PCenter = Pbase + (Size / 2.0).xx;
   float2 st = (xy - Pbase) / Size;

   float3 cTop = 0.0.xxx;
   float3 cBottom = 0.0.xxx;
   float3 invOff = 1.0.xxx - EdgeColor.rgb;

   if ((st.x > st.y) && any (st > threshholdB)) { cTop = invOff; }

   if ((st.x > st.y) && any (st < Threshhold)) { cBottom = invOff; }

   float4 tileColor = tex2D (FgSampler, PCenter);

   return float4 (max (0.0.xxx, (tileColor.rgb + cBottom - cTop)), tileColor.a);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE tilesPS ();
   }
}
