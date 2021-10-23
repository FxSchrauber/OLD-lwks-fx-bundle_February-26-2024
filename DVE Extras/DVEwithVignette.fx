// @Maintainer jwrl
// @Released 2021-09-10
// @Author jwrl
// @Created 2021-09-10
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_vignette_640.png

/**
 This effect is a simple 2D DVE with the ability to apply a circular, diamond or square
 shaped mask.  The foreground image can be sized, positioned, flipped and flopped.  Since
 flipping or flopping will change the direction of movement of the foreground position
 parameters it may be advisable to adjust the position before changing the foreground
 orientation.

 The aspect ratio of the mask can be adjusted, so ellipses and rectangles can be created.
 The aspect ratio will also affect the edge softness and border thickness.  Sufficient
 range has been given to the mask size parameter to allow the frame to be filled if needed.

 The mask can be repositioned, taking the foreground image with it.  The edges of the
 mask can be bordered with a bicolour shaded surround.  Drop shadowing is included, and
 the border and shadow can be independently feathered.

 There is no cropping provided, since the vignette is felt to be sufficient for most
 reasonable needs.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DVEwithVignette.fx
//
// Version history:
//
// Rebuilt 2021-09-10 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "DVE with vignette";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A simple DVE with circular, diamond or square shaped masking";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0,1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D (SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D (SHADER, XY))

#define odd(X) (X - floor (X / 2.0) * 2.0)

#define RADIUS_SCALE  1.6666666667
#define SQUARE_SCALE  2.0
#define FEATHER_SCALE 0.05
#define FEATHER_DMND  0.0375
#define FEATHER_SOFT  0.0005
#define BORDER_SCALE  0.1
#define BORDER_DMND   0.075

#define CIRCLE        2.0327959639
#define SQUARE        2.0
#define DIAMOND       1.4142135624

#define MIN_SIZE      0.9
#define MAX_SIZE      9.0
#define MAX_ASPECT    5.0
#define MIN_ASPECT    0.9999999999

#define FLIP          1
#define FLOP          2
#define FLIP_FLOP     3

#define FRAME_CENTRE  0.5.xx

#define HALF_PI       1.5707963268

float _OutputAspectRatio; 

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fgd, s_Foreground);
DefineInput (Bgd, s_Background);

DefineTarget (Inp, s_Input);
DefineTarget (InB, s_InBgd);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float FgSize
<
   string Group ="Foreground";
   string Description = "Size change";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int FlipFlop
<
   string Group ="Foreground";
   string Description = "Foreground orientation";
   string Enum = "Normal,Flip,Flop,Flip / flop";
> = 0;

float FgPosX
<
   string Group ="Foreground";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float FgPosY
<
   string Group ="Foreground";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int SetTechnique
<
   string Group ="Mask";
   string Description = "Mask shape";
   string Enum = "Circle / ellipse,Square / rectangle,Diamond";
> = 0;

float Radius
<
   string Group ="Mask";
   string Description = "Mask size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.125;

float Aspect
<
   string Group ="Mask";
   string Description = "Aspect ratio";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OverlayPosX
<
   string Group ="Mask";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OverlayPosY
<
   string Group ="Mask";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BorderWidth
<
   string Group ="Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float BorderFeather
<
   string Group ="Border";
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float4 BorderColour
<
   string Group ="Border";
   string Description = "Inner colour";
> = { 0.2, 0.8, 0.8, 1.0 };

float4 BorderColour_1
<
   string Group ="Border";
   string Description = "Outer colour";
> = { 0.2, 0.1, 1.0, 1.0 };

float Shadow
<
   string Group ="Drop shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowSoft
<
   string Group ="Drop shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float ShadowX
<
   string Group ="Drop shadow";
   string Description = "Offset";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.25;

float ShadowY
<
   string Group ="Drop shadow";
   string Description = "Offset";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.25;

float BgSize
<
   string Group = "Background";
   string Description = "Size change";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

int BgFlipFlop
<
   string Group = "Background";
   string Description = "Background orientation";
   string Enum = "Normal,Flip,Flop,Flip / flop";
> = 0;

float BgPosX
<
   string Group = "Background";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BgPosY
<
   string Group = "Background";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return BdrPixel (s_Foreground, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_Background, uv); }

float4 ps_circle (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (uv.x - OverlayPosX, uv.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspctR = Aspect - 0.5;
   float size   = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope  = max (0.0, Radius) * CIRCLE;
   float fthr   = BorderFeather * FEATHER_SCALE;
   float border = scope + BorderWidth * BORDER_SCALE;
   float offset = scope - fthr;
   float mix    = border + fthr - offset;

   aspctR = 1.0 - max (aspctR, 0.0) - (min (aspctR, 0.0) * 8.0);

   float2 range = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   float radius = length (float2 (range.x / aspctR, (range.y / _OutputAspectRatio) * aspctR)) * RADIUS_SCALE;
   float alpha  = (fthr > 0.0) ? saturate ((border + fthr - radius) / (fthr * 2.0)) : 1.0;

   mix = (mix > 0.0) ? saturate ((radius - offset) / mix) : 0.0;

   float4 retval = Overflow (xy2) ? BLACK : tex2D (s_Input, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (radius > border + fthr) return EMPTY;

   if (radius < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - radius) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

float4 ps_square (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (uv.x - OverlayPosX, uv.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspctR = Aspect - 0.5;
   float size   = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope  = max (0.0, Radius) * SQUARE;
   float fthr   = BorderFeather * FEATHER_SCALE;
   float border = scope + BorderWidth * BORDER_SCALE;
   float offset = scope - fthr;
   float mix    = border + fthr - offset;

   aspctR = 1.0 - max (aspctR, 0.0) - (min (aspctR, 0.0) * 8.0);

   float2 range = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   float square = max (abs (range.x / aspctR), abs (range.y * aspctR / _OutputAspectRatio)) * SQUARE_SCALE;
   float alpha  = (fthr > 0.0) ? saturate ((border + fthr - square) / (fthr * 2.0)) : 1.0;

   mix = (mix > 0.0) ? saturate ((square - offset) / mix) : 0.0;

   float4 retval = Overflow (xy2) ? BLACK : tex2D (s_Input, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (square > border + fthr) return EMPTY;

   if (square < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - square) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

float4 ps_diamond (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = float2 (uv.x - OverlayPosX, uv.y + OverlayPosY);
   float2 FgPos = float2 (FgPosX, -FgPosY);

   if (odd (FlipFlop)) {
      xy1.x = 0.5 - xy1.x;
      FgPos.x = -FgPos.x;
   }
   else xy1.x += 0.5;

   if (FlipFlop > FLIP) {
      xy1.y = 1.5 - xy1.y;
      FgPos.y = -FgPos.y;
   }
   else xy1.y -= 0.5;

   float aspect  = 1.0 - (max (Aspect - 0.5, 0.0) * MIN_ASPECT) + (max (0.5 - Aspect, 0.0) * MAX_ASPECT);
   float size    = 1.0 - (max (FgSize, 0.0) * MIN_SIZE) - (min (FgSize, 0.0) * MAX_SIZE);
   float scope   = max (0.0, Radius) * DIAMOND;
   float border  = scope + (BorderWidth * BORDER_DMND);
   float fthr    = BorderFeather * FEATHER_DMND;
   float offset  = max (scope - fthr, 0.0);
   float mix     = border + fthr - offset;
   float diamond = (abs (xy1.x - 0.5) / aspect) + (abs (xy1.y - 0.5) * aspect / _OutputAspectRatio);
   float alpha   = (fthr > 0.0) ? saturate ((border + fthr - diamond) / (fthr * 2.0)) : 1.0;

   float2 range  = FRAME_CENTRE - xy1;
   float2 xy2   = FRAME_CENTRE - (range * size) - FgPos;

   mix = (mix > 0.0) ? saturate ((diamond - offset) / mix) : 0.0;

   float4 retval = Overflow (xy2) ? BLACK : tex2D (s_Input, xy2);
   float4 colour = float4 (lerp (BorderColour.rgb, BorderColour_1.rgb, mix), alpha);

   if (diamond > border + fthr) return EMPTY;
   
   if (diamond < offset) return retval;

   alpha  = (fthr > 0.0) ? saturate ((scope + fthr - diamond) / (fthr * 2.0)) : 0.0;
   colour = lerp (colour, retval, alpha);
   mix    = sin (min (BorderWidth * 10.0, 1.0) * HALF_PI);

   return lerp (float4 (retval.rgb, alpha), colour, mix);
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy1 = uv - float2 (ShadowX, -ShadowY * _OutputAspectRatio) * 0.04;
   float2 xy2 = float2 (1.0, _OutputAspectRatio) * FEATHER_SOFT;
   float2 xy3 = (uv - FRAME_CENTRE) * (1.0 - (max (BgSize, 0.0) * MIN_SIZE) - (min (BgSize, 0.0) * MAX_SIZE));

   xy3.x = odd (BgFlipFlop)  ? 0.5 + BgPosX - xy3.x : 0.5 + xy3.x - BgPosX;
   xy3.y = BgFlipFlop > FLIP ? 0.5 - xy3.y - BgPosY : 0.5 + xy3.y + BgPosY;

   float alpha    = Overflow (xy1) ? 0.0 : tex2D (s_Input, xy1).a * 0.03125;
   float softness = ShadowSoft * 4.0;
   float amount   = 0.125;
   float feather  = 0.0;

   for (int i = 0; i < 4; i++) {
      feather += softness;
      amount  /= 2.0;

      alpha += tex2D (s_Input, xy1 + float2 (xy2.x, 0.0) * feather).a * amount;
      alpha += tex2D (s_Input, xy1 - float2 (xy2.x, 0.0) * feather).a * amount;

      alpha += tex2D (s_Input, xy1 + float2 (0.0, xy2.y) * feather).a * amount;
      alpha += tex2D (s_Input, xy1 - float2 (0.0, xy2.y) * feather).a * amount;

      alpha += tex2D (s_Input, xy1 + xy2 * feather).a * amount;
      alpha += tex2D (s_Input, xy1 - xy2 * feather).a * amount;

      alpha += tex2D (s_Input, xy1 + float2 (xy2.x, -xy2.y) * feather).a * amount;
      alpha += tex2D (s_Input, xy1 - float2 (xy2.x, -xy2.y) * feather).a * amount;
   }

   alpha = saturate (alpha * Shadow * 0.5);

   float4 Fgnd   = GetPixel (s_Input, uv);
   float4 Bgnd   = GetPixel (s_InBgd, xy3);
   float4 retval = float4 (lerp (Bgnd.rgb, 0.0.xxx, alpha), Bgnd.a);

   return lerp (retval, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique circle_DVE
{
   pass P_0 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = InB;"; > ExecuteShader (ps_initBg)
   pass P_2 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_circle)
   pass P_3 ExecuteShader (ps_main)
}

technique square_DVE
{
   pass P_0 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = InB;"; > ExecuteShader (ps_initBg)
   pass P_2 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_square)
   pass P_3 ExecuteShader (ps_main)
}

technique diamond_DVE
{
   pass P_0 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = InB;"; > ExecuteShader (ps_initBg)
   pass P_2 < string Script = "RenderColorTarget0 = Inp;"; > ExecuteShader (ps_diamond)
   pass P_3 ExecuteShader (ps_main)
}

