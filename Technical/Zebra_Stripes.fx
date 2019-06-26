// @Maintainer jwrl
// @Released 2018-12-27
// @Author jwrl
// @Created 2016-04-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Zebra_640.png

/**
This effect displays zebra patterning in over white and under black areas of the frame.
The settings are adjustable but default to 16-239 (8 bit).  Settings display as 8 bit
values to make setting up simpler, but in a 10-bit project they will be internally
scaled to 10 bits.  This is consistent with other Lightworks level settings.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect Zebra_Stripes.fx
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified by LW user jwrl 6 December 2018.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zebra pattern";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Displays zebra patterning in over white and under black areas of the frame";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state {
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float whites
<
   string Description = "White level";
   float MinVal = 0;
   float MaxVal = 255;
> = 235;

float blacks
<
   string Description = "Black level";
   float MinVal = 0;
   float MaxVal = 255;
> = 16;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SCALE_PIXELS 400.00

#define STRIPES      6.0

#define RED_LUMA     0.3
#define GREEN_LUMA   0.59
#define BLUE_LUMA    0.11

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (InputSampler, xy);

   float luma = dot (retval.rgb, float3 (RED_LUMA, GREEN_LUMA, BLUE_LUMA));
   float peak_white = whites / 255.0;
   float full_black = blacks / 255.0;

   float x = xy.x * SCALE_PIXELS;
   float y = xy.y * SCALE_PIXELS;

   x = frac (x / STRIPES);
   y = frac (y / STRIPES);

   if (luma >= peak_white) retval.rgb = (retval.rgb + float (round (frac (x + y))).xxx) / 2.0;

   if (luma <= full_black) retval.rgb = (retval.rgb + float (round (frac (x + 1.0 - y))).xxx) / 2.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Zebra_Stripes
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
