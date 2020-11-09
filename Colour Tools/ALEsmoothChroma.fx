// @Maintainer jwrl
// @Released 2020-11-09
// @Author baopao
// @Created 2013-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/ALE_SmoothChroma_640.png

/**
 This smooths the colour component of video media.  Its most appropriate use is probably
 to smooth chroma in 4:2:0 footage.  It works by converting the RGB signal to YCbCr then
 blurs just the chroma Cb/Cr components.  The result is then converted back to RGB using
 the original Y channel.  This ensures that luminance sharpness is maintained and just
 the colour component is softened.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ALEsmoothChroma.fx
//
// Feedback should be to http://www.alessandrodallafontana.com/ 
//
// Version history:
//
// Update 2020-11-09 jwrl:
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2020-08-05
// Clamped video levels on entry to and exit from the effect.  Floating point processing
// can result in video level overrun which can impact exports poorly.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 30 July 2017 jwrl.
//
// Modified 11 February 2017 by jwrl:
// Added subcategory to Fx header.
//-----------------------------------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "ALE smooth chroma";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "This smooths the colour component of video media leaving the luminance unaffected";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture fg;

sampler InputSampler = sampler_state
{
   Texture = <fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAmount
<
   string Description = "BlurAmount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main( float2 xy1 : TEXCOORD1 ) : COLOR
{
   float4 ret = saturate (tex2D( InputSampler, xy1));
   float4 ret_NoBlur = ret;

   float amount = BlurAmount * 0.01;


   float4 blurred = ret;
   blurred += tex2D( InputSampler, xy1 + float2( -amount,  0.000 ) );
   blurred += tex2D( InputSampler, xy1 + float2(  amount,  0.000 ) );
   blurred += tex2D( InputSampler, xy1 + float2(  0.000, -amount ) );
   blurred += tex2D( InputSampler, xy1 + float2(  0.000,  amount ) );
   blurred += tex2D( InputSampler, xy1 + float2( -amount*2,  0.000 ) );
   blurred += tex2D( InputSampler, xy1 + float2(  amount*2,  0.000 ) );
   blurred += tex2D( InputSampler, xy1 + float2(  0.000, -amount*2 ) );
   blurred += tex2D( InputSampler, xy1 + float2(  0.000,  amount*2 ) );
   blurred /= 9.0;

   ret = blurred;


//RGB2YCbCr
  
   float Y = 0.065 + ( ret_NoBlur.r * 0.257 ) + ( ret_NoBlur.g * 0.504 ) + ( ret_NoBlur.b * 0.098 );
   float Cb = 0.5 - ( ret.r * 0.148 ) - ( ret.g * 0.291 ) + ( ret.b * 0.439 );
   float Cr = 0.5 + ( ret.r * 0.439 ) - ( ret.g * 0.368 ) - ( ret.b * 0.071 );



//YCbCr2RGB   
   float4 o_color;

   o_color.r = 1.164*(Y - 0.065) + 1.596*(Cr - 0.5);
   o_color.g = 1.164*(Y - 0.065) - 0.813*(Cr - 0.5) - 0.392*(Cb - 0.5);
   o_color.b = 1.164*(Y - 0.065) + 2.017*(Cb - 0.5);
   o_color.a = 1;


   return saturate (o_color);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique singletechnique { pass Single_Pass { PixelShader = compile PROFILE ps_main(); } }
