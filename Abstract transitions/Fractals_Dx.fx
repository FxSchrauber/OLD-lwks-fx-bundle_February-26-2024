// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @OriginalAuthor "Robert Sch�tze"
// @Created 2016-05-21
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Fractals_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FractalDissolve.mp4

/**
This effect uses a fractal-like pattern to transition between two sources.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractals_Dx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Sch�tze (trirop) 07.12.2015.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from FractalDiss.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 23 December 2018 jwrl.
// Added "Notes" section to _LwksEffectInfo.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal dissolve";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Uses a fractal-like pattern to transition between sources";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture FracOut : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Fractals = sampler_state
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

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float fractalOffset
<
   string Description = "Fractal offset";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Rate
<
   string Description = "Fractal rate";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Border
<
   string Description = "Border";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float Feather
<
   string Description = "Feather";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fractal (float2 xy : TEXCOORD1) : COLOR
{
   float speed = _Progress * Rate;
   float3 fractal = float3 (xy.x / _OutputAspectRatio, xy.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - float3 (1.0, 1.0, speed * 0.5))));
   }

   return float4 (fractal, 1.0);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy);
   float4 Bgd = tex2D (s_Background, xy);
   float4 retval = tex2D (s_Fractals, xy);

   float fractal = max (retval.g, max (retval.r, retval.b));
   float bdWidth = Border * 0.1;
   float FthrRng = Amount + Feather;

   if (fractal <= FthrRng) {
      if (fractal > (Amount - bdWidth)) { retval = lerp (Bgd, retval, (fractal - Amount) / Feather); }
      else retval = Bgd;
   }

   if (fractal > FthrRng) { retval = Fgd; }
   else if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Fgd, (fractal - Amount) / Feather); }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Fractals_Dx
{
   pass P_1
   < string Script = "RenderColorTarget0 = FracOut;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
