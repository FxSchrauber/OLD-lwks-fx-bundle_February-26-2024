// @Maintainer jwrl
// @Released 2020-04-04
// @Author jwrl
// @Created 2020-04-03
// @see https://www.lwks.com/media/kunena/attachments/6375/RadialGradient_640.png

/**
 This generates a radial colour gradient, the centre point of which can be adjusted.  The
 aspect ratio can also be corrected for, changing the geometry from circular to an ellipse
 defined by the aspect ratio of the video format.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RadialGrad.fx
//
// Modified 2020-04-04 - jwrl.
// Added aspect ratio correction and a means of varying the amount of correction applied.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Radial gradiant";
   string Category    = "Mattes";
   string SubCategory = "Simple tools";
   string Notes       = "Creates a colour field with a radial gradiant";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 OuterColour
<
   string Group = "Colour range";
   string Description = "Outer colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 CentreColour
<
   string Group = "Colour range";
   string Description = "Centre colour";
   bool SupportsAlpha = true;
> = { 0.314, 0.784, 1.0, 1.0 };

float Aspect
<
   string Group = "Colour range";
   string Description = "Aspect ratio";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float OffsX
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsY
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Declarations and definitons
//-----------------------------------------------------------------------------------------//

#define PI    3.141592654

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD0, float2 xy2 : TEXCOORD1) : COLOR
{
   float2 xy1 = xy - 0.5.xx;

   if (_OutputAspectRatio < 0) { xy1.x *= _OutputAspectRatio; }
   else xy1.y /= _OutputAspectRatio;

   xy1 = lerp (xy1 + 0.5.xx, xy, Aspect);

   float buff_0 = (OffsX <= 0.0) ? (xy1.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? xy1.x / 2.0 :
                  (OffsX > xy1.x) ? xy1.x / (2.0 * OffsX) : ((xy1.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (xy1.y / 2.0) + 0.5 :
            (vert >= 1.0) ? xy1.y / 2.0 :
            (vert > xy1.y) ? xy1.y / (2.0 * vert) : ((xy1.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 Bgnd     = tex2D (s_Input, xy2);
   float4 gradient = lerp (OuterColour, CentreColour, horiz);

   gradient = lerp (OuterColour, gradient, vert);

   return lerp (Bgnd, gradient, gradient.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RadialGrad
{
   pass P_1 
   { PixelShader = compile PROFILE ps_main (); }
}
