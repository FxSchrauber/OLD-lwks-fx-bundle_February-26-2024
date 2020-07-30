// @Maintainer jwrl
// @Released 2020-07-30
// @Author jwrl
// @Created 2017-09-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_xPinch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_xPinch.mp4

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot, while zooming out of the pinched image.  It can also reverse the process to bring
 in the incoming video.

 The direction swap has been deliberately made asymmetric.  Subjectively it looked better
 to have the pinch established before the zoom out started, but to run the zoom in through
 the entire un-pinch process.  Trig functions are used on the effect progress to make the
 acceleration smoother.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect xPinch_Dx.fx
//
// Version history:
//
// Modified 2020-07-30 jwrl.
// Reformatted the effect header.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "X-pinch";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Pinches the outgoing video to an X-shape then a user-defined point to reveal the incoming shot";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Pinch : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Pinch = sampler_state
{
   Texture   = <Pinch>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MID_PT  (0.5).xx
#define HALF_PI 1.5707963

#define EMPTY   (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_pinch_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = sin (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_illegal (xy) ? EMPTY : tex2D (s_Foreground, xy);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 outgoing = fn_illegal (xy) ? EMPTY : tex2D (s_Pinch, xy);

   return lerp (tex2D (s_Background, uv), outgoing, outgoing.a);
}

float4 ps_pinch_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = cos (Amount * HALF_PI);

   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return fn_illegal (xy) ? EMPTY : tex2D (s_Background, xy);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = 1.0 - sin (Amount * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   float4 incoming = fn_illegal (xy) ? EMPTY : tex2D (s_Pinch, xy);

   return lerp (tex2D (s_Foreground, uv), incoming, incoming.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_Pinch_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_1 (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Dx_Pinch_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Pinch;"; >
   { PixelShader = compile PROFILE ps_pinch_2 (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_2 (); }
}
