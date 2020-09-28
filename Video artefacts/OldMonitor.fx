// @Maintainer jwrl
// @Released 2020-09-28
// @Author juhartik
// @Created 2011-08-01
// @see https://www.lwks.com/media/kunena/attachments/6375/jh_stylize_oldmonitor_640.png

/**
 This old monitor effect is black and white with scan lines, which are fully adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OldMonitor.fx
// 
// JH Stylize Vignette v1.0 - Juha Hartikainen - juha@linearteam.org - Emulates old
// Hercules monitor
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
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined FgSampler to fix cross platform default sampler state differences.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added "Simulation" subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Old monitor";      
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "This old monitor effect gives a black and white image with fully adjustable scan lines";
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

float4 LineColor
<
   string Description = "Scanline Color";
   bool SupportsAlpha = false;
> = { 1.0f, 1.0f, 1.0f, 1.0f };

float LineCount
<
   string Description = "Scanline Count";
   float MinVal       = 100.0f;
   float MaxVal       = 1080.0f;
> = 300.0f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define _PI 3.14159265

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 OldMonitorPS(float2 xy : TEXCOORD1) : COLOR {
    float4 color;
	float intensity;
	float multiplier;
	float oldalpha;
	
    color = tex2D(FgSampler, xy);
	oldalpha = color.a;
	
	intensity = (color.r+color.g+color.b)/3;
   
    multiplier = (sin(_PI*xy.y*LineCount)+1.0f)/2.0f;
   
    color = LineColor*intensity*multiplier;
	color.a = oldalpha;
   
    return color;
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE OldMonitorPS();
   }
}
