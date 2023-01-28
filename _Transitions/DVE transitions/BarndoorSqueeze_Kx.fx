// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is similar to the split squeeze effect, customised to suit its use with blended
 effects.  It moves the separated foreground image halves apart and squeezes them to
 the edges of the screen or expands the halves from the edges.  It can operate either
 vertically or horizontally depending on the user setting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarndoorSqueeze_Fx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Barn door squeeze (keyed)", "Mix", "DVE transitions", "Splits the foreground and squeezes the halves apart horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "H start (delta folded)|V start (delta folded)|At start (horizontal)|At end (horizontal)|At start (vertical)|At end (vertical)");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Split, "Split centre", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, float2 xy1, float2 xy2)
{
   float4 Fgnd = tex2D (F, xy2);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, xy1);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Expand_Hf

DeclarePass (Bg_Hf)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_Hf)
{ return fn_keygen_F (Bg_Hf, uv2, uv3); }

DeclareEntryPoint (Expand_Hf)
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (Super_Hf, float2 ((uv3.x + amount) / Amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (Super_Hf, float2 (uv3.x / Amount, uv3.y)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Hf, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Expand_Vf

DeclarePass (Bg_Vf)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_Vf)
{ return fn_keygen_F (Bg_Vf, uv2, uv3); }

DeclareEntryPoint (Expand_Vf)
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Super_Vf, float2 (uv3.x, (uv3.y + amount) / Amount))
               : (uv3.y < negAmt) ? tex2D (Super_Vf, float2 (uv3.x, uv3.y / Amount)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Vf, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Expand_H

DeclarePass (Bg_He)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_He)
{ return fn_keygen (Bg_He, uv1, uv3); }

DeclareEntryPoint (Expand_H)
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (Super_He, float2 ((uv3.x + amount) / Amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (Super_He, float2 (uv3.x / Amount, uv3.y)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_He, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Squeeze_H

DeclarePass (Bg_Hs)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Hs)
{ return fn_keygen (Bg_Hs, uv1, uv3); }

DeclareEntryPoint (Squeeze_H)
{
   float amount = 1.0 - Amount;
   float negAmt = amount * Split;
   float posAmt = 1.0 - (amount * (1.0 - Split));

   float4 Fgnd = (uv3.x > posAmt) ? tex2D (Super_Hs, float2 ((uv3.x - Amount) / amount, uv3.y))
               : (uv3.x < negAmt) ? tex2D (Super_Hs, float2 (uv3.x / amount, uv3.y)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Hs, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Expand_V

DeclarePass (Bg_Ve)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Ve)
{ return fn_keygen (Bg_Ve, uv1, uv3); }

DeclareEntryPoint (Expand_V)
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Super_Ve, float2 (uv3.x, (uv3.y + amount) / Amount))
               : (uv3.y < negAmt) ? tex2D (Super_Ve, float2 (uv3.x, uv3.y / Amount)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Ve, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Squeeze_V

DeclarePass (Bg_Vs)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Vs)
{ return fn_keygen (Bg_Vs, uv1, uv3); }

DeclareEntryPoint (Squeeze_V)
{
   float amount = 1.0 - Amount;
   float negAmt = amount * (1.0 - Split);
   float posAmt = 1.0 - (amount * Split);

   float4 Fgnd = (uv3.y > posAmt) ? tex2D (Super_Vs, float2 (uv3.x, (uv3.y - Amount) / amount))
               : (uv3.y < negAmt) ? tex2D (Super_Vs, float2 (uv3.x, uv3.y / amount)) : kTransparentBlack;

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_Vs, uv3), Fgnd, Fgnd.a);
}

