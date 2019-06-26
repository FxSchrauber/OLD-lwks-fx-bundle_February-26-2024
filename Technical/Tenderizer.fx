// @Maintainer jwrl
// @Released 2018-12-27
// @Author khaver
// @Created 2016-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Tenderizer_640.png

/**
This effect converts 8 bit video to 10 bit video by adding intermediate colors and luminance
values using spline interpolation.  Set project to 10 bit and set source width and height
for best results.

Note: the alpha channel is not changed, but there may be some image softening.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Tenderizer.fx
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 6 December 2018.
// Added creation date.
// Changed category.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tenderizer";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "Converts 8 bit video to 10 bit video by adding intermediate levels using spline interpolation";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture V;

sampler VSampler = sampler_state {
	Texture = <V>;
        AddressU = Mirror;
        AddressV = Mirror;
        MinFilter = Point;
        MagFilter = Point;
        MipFilter = Point;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int ReX
<
   string Description = "Source Horizontal Resolution";
   string Enum = "Project,720,1280,1440,1920,2048,3840,4096";
> = 4;

int ReY
<
   string Description = "Source Vertical Resolution";
   string Enum = "Project,480,576,720,1080,2160,";
> = 4;

bool Luma
<
   string Description = "Tenderize Luma";
> = true;

bool Chroma
<
   string Description = "Tenderize Chroma";
> = true;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hermite(float t, float4 A, float4 B, float4 C, float4 D)
{
	float t2 = t * t;
	float t3 = t * t * t;
	float4 a = -A/2.0 + (3.0*B)/2.0 - (3.0*C)/2.0 + D/2.0;
	float4 b = A - (5.0*B)/2.0 + 2.0*C - D / 2.0;
	float4 c = -A/2.0 + C/2.0;
	float4 d = B;

	return a*t3 + b*t2 + c*t + d;
}

float4 colorsep(sampler samp, float2 xy, float2 pix)
{
	float4 color, col;
	col.rgb = tex2D(samp, xy + pix).rgb;
	float Cmin = min(col.r, min(col.g, col.b));
	float Red = col.r - Cmin;
	float Green = col.g - Cmin;
	float Blue = col.b - Cmin;
	color = float4(Red, Green, Blue, Cmin);
	return color;
}

float closest(float test, float orig, float bit)
{
	if (abs(test - orig) < (bit * 0.3333)) return orig;
        else {
		if (abs(test - orig) < (bit * 0.6667)) return test;
		else return (test + orig) / 2.0;
	}
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Tenderize( float2 xy : TEXCOORD1 ) : COLOR
{
   float2 pixel;
   float2 Cpixel;
   if (ReX == 0) pixel.x =  1.0f / _OutputWidth;
   if (ReX == 1) pixel.x = 1.0f / 720.0;
   if (ReX == 2) pixel.x = 1.0f / 1280.0;
   if (ReX == 3) pixel.x = 1.0f / 1440.0;
   if (ReX == 4) pixel.x = 1.0f / 1920.0;
   if (ReX == 5) pixel.x = 1.0f / 2048.0;
   if (ReX == 6) pixel.x = 1.0f / 3840.0;
   if (ReX == 7) pixel.x = 1.0f / 4096.0;
   if (ReY == 0) pixel.y =  1.0f / OutputHeight;
   if (ReY == 1) pixel.y = 1.0f / 480.0;
   if (ReY == 2) pixel.y = 1.0f / 576.0;
   if (ReY == 3) pixel.y = 1.0f / 720.0;
   if (ReY == 4) pixel.y = 1.0f / 1080.0;
   if (ReY == 5) pixel.y = 1.0f / 2160.0;
   Cpixel = pixel;
   float4 orig = tex2D(VSampler, xy);
   float alpha = orig.a;
   float4 color;
   //xy = xy + (pixel / 2.0);
   float4 seporg = colorsep(VSampler, xy, float2(0,0));
   //return seporg;
   float cbit = 1.0 / 256.0;
   float R, G, B, L;
   //if (1 - direction) {
float4 samp10, samp11, samp13, samp14;
float4 samp20, samp21, samp23, samp24;
float4 samp30, samp31, samp33, samp34;
float4 samp40, samp41, samp43, samp44;
float4 samp50, samp51, samp53, samp54;
float4 samp60, samp61, samp63, samp64;
float4 samp70, samp71, samp73, samp74;
float4 samp80, samp81, samp83, samp84;
             samp10 = colorsep(VSampler, xy, float2(Cpixel.x * -2.0, 0));
             samp11 = colorsep(VSampler, xy, float2(-Cpixel.x, 0));
             samp13 = colorsep(VSampler, xy, float2(Cpixel.x, 0));
             samp14 = colorsep(VSampler, xy, float2(Cpixel.x * 2.0, 0));
             samp20 = colorsep(VSampler, xy, float2((Cpixel.x * -2.0), -Cpixel.y));
             samp21 = (colorsep(VSampler, xy, float2(-Cpixel.x, 0)) + colorsep(VSampler, xy, float2(-Cpixel.x, -Cpixel.y))) / 2.0;
             samp23 = (colorsep(VSampler, xy, float2(Cpixel.x, 0)) + colorsep(VSampler, xy, float2(Cpixel.x, Cpixel.y))) / 2.0;
             samp24 = colorsep(VSampler, xy, float2(Cpixel.x * 2.0, Cpixel.y));
             samp30 = colorsep(VSampler, xy, float2(Cpixel.x * -2.0, Cpixel.y * -2.0));
             samp31 = colorsep(VSampler, xy, float2(-Cpixel.x, -Cpixel.y));
             samp33 = colorsep(VSampler, xy, float2(Cpixel.x, Cpixel.y));
             samp34 = colorsep(VSampler, xy, float2(Cpixel.x * 2.0, Cpixel.y * 2.0));
             samp40 = colorsep(VSampler, xy, float2(-Cpixel.x, Cpixel.y * -2.0));
             samp41 = (colorsep(VSampler, xy, float2(-Cpixel.x, -Cpixel.y)) + colorsep(VSampler, xy, float2(0, -Cpixel.y))) / 2.0;
             samp43 = (colorsep(VSampler, xy, float2(0, Cpixel.y)) + colorsep(VSampler, xy, float2(Cpixel.x, Cpixel.y))) / 2.0;
             samp44 = colorsep(VSampler, xy, float2(Cpixel.x, Cpixel.y * 2.0));
             samp50 = colorsep(VSampler, xy, float2(0, Cpixel.y * -2.0));
             samp51 = colorsep(VSampler, xy, float2(0, -Cpixel.y));
             samp53 = colorsep(VSampler, xy, float2(0, Cpixel.y));
             samp54 = colorsep(VSampler, xy, float2(0, Cpixel.y * 2.0));
             samp60 = colorsep(VSampler, xy, float2(Cpixel.x, Cpixel.y * -2.0));
             samp61 = (colorsep(VSampler, xy, float2(Cpixel.x, -Cpixel.y)) + colorsep(VSampler, xy, float2(0, -Cpixel.y))) / 2.0;
             samp63 = (colorsep(VSampler, xy, float2(0, Cpixel.y)) + colorsep(VSampler, xy, float2(-Cpixel.x, Cpixel.y))) / 2.0;
             samp64 = colorsep(VSampler, xy, float2(-Cpixel.x, Cpixel.y * 2.0));
             samp70 = colorsep(VSampler, xy, float2(Cpixel.x * 2.0, Cpixel.y * -2.0));
             samp71 = colorsep(VSampler, xy, float2(Cpixel.x, -Cpixel.y));
             samp73 = colorsep(VSampler, xy, float2(-Cpixel.x, Cpixel.y));
             samp74 = colorsep(VSampler, xy, float2(Cpixel.x * -2.0, Cpixel.y * 2.0));
             samp80 = colorsep(VSampler, xy, float2(Cpixel.x * -2.0, Cpixel.y));
             samp81 = (colorsep(VSampler, xy, float2(-Cpixel.x, 0)) + colorsep(VSampler, xy, float2(-Cpixel.x, Cpixel.y))) / 2.0;
             samp83 = (colorsep(VSampler, xy, float2(Cpixel.x, 0)) + colorsep(VSampler, xy, float2(Cpixel.x, -Cpixel.y))) / 2.0;
             samp84 = colorsep(VSampler, xy, float2(Cpixel.x * 2.0, -Cpixel.y));
      float4 samp1 = Hermite(0.5, samp10, samp11, samp13, samp14);
      float4 samp2 = Hermite(0.5, samp20, samp21, samp23, samp24);
      float4 samp3 = Hermite(0.5, samp30, samp31, samp33, samp34);
      float4 samp4 = Hermite(0.5, samp40, samp41, samp43, samp44);
      float4 samp5 = Hermite(0.5, samp50, samp51, samp53, samp54);
      float4 samp6 = Hermite(0.5, samp60, samp61, samp63, samp64);
      float4 samp7 = Hermite(0.5, samp70, samp71, samp73, samp74);
      float4 samp8 = Hermite(0.5, samp80, samp81, samp83, samp84);
      if (Chroma) {
         R = (samp1.r + samp2.r + samp3.r + samp4.r + samp5.r + samp6.r + samp7.r + samp8.r) / 8.0;
         G = (samp1.g + samp2.g + samp3.g + samp4.g + samp5.g + samp6.g + samp7.g + samp8.g) / 8.0;
         B = (samp1.b + samp2.b + samp3.b + samp4.b + samp5.b + samp6.b + samp7.b + samp8.b) / 8.0;
	 R = closest(R, seporg.r, cbit);
	 G = closest(G, seporg.g, cbit);
	 B = closest(B, seporg.b, cbit);
      }
      else {
         R = seporg.r;
         G = seporg.g;
         B = seporg.b;
      }
      
      if (Luma) {
         L = (samp1.a + samp2.a + samp3.a + samp4.a + samp5.a + samp6.a + samp7.a + samp8.a) / 8.0;
	 L = closest(L, seporg.a, cbit);
      }
      else L = seporg.a;
      color = float4(R + L, G + L, B + L, alpha);
   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Tenderizer
{
   pass First
   {
      PixelShader = compile PROFILE Tenderize();
   }
}
