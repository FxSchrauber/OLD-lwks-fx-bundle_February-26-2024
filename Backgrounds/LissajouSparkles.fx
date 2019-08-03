// @Maintainer jwrl
// @Released 2019-08-03
// @Author jwrl
// @Author baopao
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Lissajou_640.png

/**
Lissajou sparkles is based on Sinusoidal lights, a semi-abstract pattern generator created
for Mac and Linux systems by Lightworks user baopao.  This version adds either external
video or a colour gradient background to the pattern.  That has meant that the range and
type of some parameters were changed from baopao's original to allow their interactive
adjustment in the edit viewer.

NOTE: This version won't run or compile on Windows' Lightworks version 14.0 or earlier.
A legacy version is available for users in that position.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LissajouSparkles.fx
//
// Lissajou sparkles is based on Sinusoidal lights, a semi-abstract pattern generator
// created for Mac and Linux systems by Lightworks user baopao.  That was in turn based
// on the Lissajou code at http://glslsandbox.com/e#9996.0
//
// Windows conversion was carried out by Lightworks user jwrl.
//
// LW 14+ version by jwrl 12 February 2017
// Category changed from "Generators" to "Mattes", SubCategory "Patterns" added.
//
// LW 14.5 update by jwrl 30 March 2018
// Under Windows this must compile as ps_3.0 or better.  This is automatically taken
// care of in versions of LW higher than 14.0.  If using an older version under
// Windows the Legacy version must be used.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 31 May 2018 jwrl.
// Changed Num description from "Number" to "Star number".
// Changed Level description from "Intensity" to "Glow intensity".
// Reversed direction of action of CentreX parameter.
// Fixed default colours not displaying.
// Performed general code cleanup to improve efficiency.
//
// Modified 29 September 2018 jwrl.
// Added notes to header.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Inverted speed setting.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 3 August 2019 jwrl.
// Corrected matte generation so that it remains stable without an input.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lissajou sparkles";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "A pattern generator that creates coloured stars in Lissajou curves over a coloured background";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Bgd : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };
sampler s_Background = sampler_state { Texture = <Bgd>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float StarNumber
<
   string Description = "Star number";
   string Group = "Pattern";
   float MinVal = 0.0;
   float MaxVal = 400;
> = 200;

float Speed
<
   string Description = "Speed";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float Scale
<
   string Description = "Scale";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.33;

float Level
<
   string Description = "Glow intensity";
   string Group = "Pattern";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float CentreX
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float ResX
<
   string Description = "Size";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.4;

float ResY
<
   string Description = "Size";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.01;
   float MaxVal = 2.0;
> = 0.4;

float SineX
<
   string Description = "Frequency";
   string Group = "Pattern";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 4.00;

float SineY
<
   string Description = "Frequency";
   string Group = "Pattern";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 8.00;

float4 fgdColour
<
   string Description = "Colour";
   string Group = "Pattern";
   bool SupportsAlpha = false;
> = { 0.85, 0.75, 0.0, 1.0 };

float extBgd
<
   string Description = "External Video";
   string Group = "Background";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.00;

float4 topLeft
<
   string Description = "Top Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.5, 0.75, 0.0 };

float4 topRight
<
   string Description = "Top Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.375, 0.75, 0.0 };

float4 botLeft
<
   string Description = "Bottom Left";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.625, 0.75, 0.0 };

float4 botRight
<
   string Description = "Bottom Right";
   string Group = "Background";
   bool SupportsAlpha = false;
> = { 0.375, 0.5625, 0.75, 0.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_background (float2 uv : TEXCOORD, float2 xy : TEXCOORD1) : COLOR
{
   float4 topRow = lerp (topLeft, topRight, uv.x);
   float4 botRow = lerp (botLeft, botRight, uv.x);
   float4 cField = lerp (topRow, botRow, uv.y);

   return lerp (cField, tex2D (s_Input, xy), extBgd);
}

float4 ps_main (float2 uv : TEXCOORD, float2 UV : TEXCOORD1) : COLOR
{
   float4 fgdPat = fgdColour;

   float2 xy = uv + float2 (0.5 - CentreX, CentreY - 0.5) * 2.0;
   float2 position;

   float scale_X    = Scale * 3.0;
   float scale_Y    = scale_X * ResY;
   float sum        = 0.0;
   float time       = _Progress * (1.0 - Speed) * 10.0;
   float Curve      = SineX * 12.5;
   float keyClip    = scale_X / ((19.0 - (Level * 14.0)) * 100.0);
   float curve_step = 0.0;
   float time_step;

   scale_X *= ResX;

   for (int i = 0; i < StarNumber; ++i) {
      time_step = (float (i) + time) / 5.0;

      position.x = sin (SineY * time_step + curve_step) * scale_X;
      position.y = sin (time_step) * scale_Y;

      sum += keyClip / length (xy - position - 0.5.xx);
      curve_step += Curve;
      }

   fgdPat.rgb *= sum;
   sum = saturate ((sum * 1.5) - 0.25);

   return lerp (tex2D (s_Background, UV), fgdPat, sum);
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

technique LissajouSparkles
{
   pass P_1
   < string Script = "RenderColorTarget0 = Bgd;"; >
   { PixelShader = compile PROFILE ps_background (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
