// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2017-10-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Sine_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_Sine.mp4

/**This is a dissolve/wipe that uses a sine distortion to do a left-right or right-left
transition between the inputs.  The phase can also be offset by 180 degrees.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sine_Dx.fx
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Sinusoidal mix";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Uses a sine distortion to do a left-right or right-left transition between the inputs";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
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
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Direction
<
   string Description = "Direction";
   string Enum = "Left to right,Right to left"; 
> = 0;

int Mode
<
   string Group = "Ripples";
   string Description = "Distortion";
   string Enum = "Upwards,Downwards"; 
> = 0;

float Width
<
   string Group = "Ripples";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ripples
<
   string Group = "Ripples";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Spread
<
   string Group = "Ripples";
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

#define EMPTY    (0.0).xxxx

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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? xy2.x : 1.0 - xy2.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 uv = (Mode == 0) ? float2 (xy2.x, xy2.y + offset) : float2 (xy2.x, xy2.y - offset);

   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = fn_illegal (uv) ? EMPTY : tex2D (BgSampler, uv);

   return lerp (Fgd, Bgd, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sine_Dx
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
