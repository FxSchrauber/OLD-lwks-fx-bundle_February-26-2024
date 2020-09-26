// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Author abelmilanes
// @Created 2017-03-04
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmExp_640.png

/**
 This is an effect that simulates exposure adjustment using a Cineon profile.  It is
 fairly accurate at the expense of requiring some reasonably complex maths.  With current
 GPU types this shouldn't be an issue.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmExposure.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 16 April 2020 jwrl.
// Removed buggy "all()" Cg expression.  Both "all()" and "any()" suffer from this Cg
// documented bug.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bug fix 10 July 2017 by jwrl.
// Corrected ambiguous declaration affecting Linux and Mac versions only.
//
// Completed 4 March 2017 by jwrl.
// This effect was started by user abelmilanes as FilmFx.fx in 2011 but was never
// completed.  This version was completed by jwrl.  Hopefully abelmilane's original
// intentions have been preserved.  In the process there has been considerable code
// cleanup for efficiency and speed reasons.  The alpha channel is now passed which
// the unfinished original didn't do.  The "amount" parameter is an addition so that
// the effect can now be faded out.
//
// The explicit profile declaration ps_2_0 was changed to the generic PROFILE for
// cross-platform reasons.  It now runs on all supported Lightworks platforms.
//
// The original version had a soft clip function which did not work - in fact it was
// commented out by abelmilanes.  It's hard to see a need for it in this current form,
// so it has been discarded.  The natural clipping in the GPU made this difficult to
// implement in any case.
//
// The "magic numbers" used in the original have been kept at their original depths of
// up to seven decimal places.  That surely can't really be necessary!!!
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film exposure";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates exposure adjustment using a Cineon profile";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InpSampler = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Exposure
<
   string Group = "Exposure";
   string Description = "Master";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float CyanRed
<
   string Group = "Exposure";
   string Description = "Cyan/red";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float MagGreen
<
   string Group = "Exposure";
   string Description = "Magenta/green";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float YelBlue
<
   string Group = "Exposure";
   string Description = "Yellow/blue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Amount
<
   string Description = "Original";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval, Src = tex2D (InpSampler, uv);

   // Convert RGB to linear

   float test = max (Src.r, max (Src.g, Src.b));   // Workaround to address Cg's all() bug

   float3 lin = (test < 0.04045) ? Src.rgb / 12.92 : pow ((Src.rgb + 0.055.xxx) / 1.055, 2.4);

   // Convert linear to Kodak Cineon

   float3 logOut   = ((log10 ((lin * 0.9892) + 0.0108) * 300.0) + 685.0) / 1023.0;
   float3 exposure = { CyanRed, MagGreen, YelBlue };

   exposure = (exposure + Exposure) * 0.1;

   // Adjust exposure then convert back to linear

   logOut = (((logOut + exposure) * 1023.0) - 685.0) / 300.0;
   lin = (pow (10.0.xxx, logOut) - 0.0108.xxx) * 1.0109179;

   // Back to RGB

   test = max (lin.r, max (lin.g, lin.b));

   retval.rgb = (test < 0.0031308) ? lin * 12.92 : (1.055 * pow (lin, 0.4166667)) - 0.055;
   retval = { saturate (retval.rgb), Src.a };

   return lerp (retval, Src, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FilmExposure
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
