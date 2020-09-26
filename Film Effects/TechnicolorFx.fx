// @Maintainer jwrl
// @Released 2020-09-27
// @Author khaver
// @Created 2011-04-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Technicolor_640.png

/**
 Simulates the look of the classic 2-strip and 3-strip Technicolor film processes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TechnicolorFx.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Added subcategory for LW14 18 February 2017 - jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Technicolor";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates the look of the classic 2-strip and 3-strip Technicolor film processes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
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

int SetTechnique
<
   string Description = "Emulation";
   string Enum = "Two_Strip,Three_Strip";
> = 0;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Techni2( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 source = tex2D( FgSampler, xy );

   float4 output;
   output.r = source.r;
   output.g = (source.g/2.0) + (source.b/2.0);
   output.b = (source.b/2.0) + (source.g/2.0);
   output.a = 0;
   return output;
}
float4 Techni3( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 source = tex2D( FgSampler, xy );

   float4 output;
   output.r = source.r - (source.g/2.0) + (source.b/2.0);
   output.g = source.g - (source.r/2.0) + (source.b/2.0);
   output.b = source.b - (source.r/2.0) + (source.g/2.0);
   output.a = 0;
   return output;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Two_Strip
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Techni2();
   }
}

technique Three_Strip
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Techni3();
   }
}
