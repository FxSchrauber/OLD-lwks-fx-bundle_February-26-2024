// @Maintainer jwrl
// @Released 2020-11-12
// @Author khaver
// @Author mu6k
// @Author Icecool
// @Author Yusef28
// @Created 2018-05-16
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_1_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/LensFlare_1.mp4

/**
 This effect creates very realistic lens flare patterns.  The file LensFlare_1.png is also
 required, and must be in the Effects Templates folder.

 ***********  WARNING: THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER  ***********
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LensFlare1.fx
//-----------------------------------------------------------------------------------------//
//
// Original Shadertoy authors:
// mu6k (2013-08-13) https://www.shadertoy.com/view/4sX3Rs
// Icecool (2014-07-06) https://www.shadertoy.com/view/XdfXRX
// Yusef28 (2016-08-19) https://www.shadertoy.com/view/Xlc3D2
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// LensFlare1.fx for Lightworks was adapted by user khaver 16 May 2018 from original
// code by the above authors taken from the Shadertoy website:
// https://www.shadertoy.com/view/4sX3Rs
// https://www.shadertoy.com/view/XdfXRX
// https://www.shadertoy.com/view/Xlc3D2
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2020-11-12 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2018-12-23:
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2018-05-18:
// Cross platform compatibility check and code optimisation.  A total of roughly twenty
// major or minor changes were found.  Additional comments identify those sections, and
// I sincerely hope that I have got them all!
//
// I chose not to do anything to correct the y coordinates, which in Lightworks are the
// inverse of the way that they're used in GLSL.  I simply changed the default CENTERY
// setting from 0.25 to 0.75 to make the flare appear in the upper half of the frame by
// default.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lens Flare #1";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Multicolor lens flare with secondary reflections and animated rays";
   bool CanSize       = true;
> = 0;

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

// jwrl: At khaver's suggestion, renamed the file below from noise.png to LensFlare_1.png.

texture _Grain < string Resource = "LensFlare_1.png"; >;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state { Texture = <Input>; };

sampler GSampler = sampler_state
{
   Texture = <_Grain>;
	AddressU = Wrap;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CENTERX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.15;

float CENTERY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float AMOUNT
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float COMPLEX
<
	string Description = "Complexity";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 10.0;

float ZOOM
<
   string Description = "Flare Zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float SCATTER
<
   string Description = "Light Scatter";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool AFFECT
<
	string Description = "Use Image";
   string Group = "Image Content";
> = false;

float THRESH
<
   string Description = "Threshold";
   string Group = "Image Content";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float GLINT
<
   string Description = "Brightness";
   string Group = "Flare Source";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float RAYS
<
   string Description = "Rays Count";
   string Group = "Flare Source";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 12.0;

bool ANIMATE
<
	string Description = "Animate Rays";
	string Group = "Flare Source";
> = true;

int BLADES
<
   string Description = "Shutter Blades";
   string Group = "Secondary Reflections";
   string Enum = "5,6,7,8";
> = 1;

float SHUTTER
<
   string Description = "Shutter Offset";
   string Group = "Secondary Reflections";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float POINTS
<
   string Description = "Points Offset";
   string Group = "Secondary Reflections";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

//-----------------------------------------------------------------------------------------//

float _Progress;
float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;  // jwrl: removed unused _LengthFrames, added _OutputAspectRatio
float _Length = 0;
#define CTIME (_Length*(1.0-_Progress))

//-----------------------------------------------------------------------------------------//

float rnd(float w)
{
    float f = frac(sin(w)*1000.);
 return f;
}

float noise1(float t)
{
	t *= 10.0;
	if (ANIMATE) return tex2D(GSampler,float2(t / _OutputWidth, 0.0)).x;
	else return 1.0;
}
float noise2(float2 t)
{
	t *= 10.0;
/*
jwrl: Changed to simplify the arithmetic.
	if (ANIMATE) return tex2D(GSampler,((t / _OutputWidth) + float2(CTIME*0.05,CTIME*0.05))).x;
	else return 1.0;
*/
   return ANIMATE ? tex2D (GSampler,((t / _OutputWidth) + (CTIME * 0.05).xx)).x : 1.0;
}
float vary()
{
	float pixX = 1.0/_OutputWidth;
	float pixY = 1.0/_OutputHeight;
	float2 iMouse = float2(CENTERX,1.0 - CENTERY);
	float4 col = tex2D(InputSampler,iMouse);
	col += tex2D(InputSampler,iMouse - float2(pixX,pixY));       // jwrl: changed from float2(iMouse.x - pixX,iMouse.y - pixY) (simplified mathematics)
	col += tex2D(InputSampler,float2(iMouse.x,iMouse.y - pixY));
	col += tex2D(InputSampler,iMouse + float2(pixX,-pixY));      // jwrl: changed from float2(iMouse.x + pixX,iMouse.y - pixY) (simplified mathematics)

	col += tex2D(InputSampler,float2(iMouse.x - pixX,iMouse.y));
	col += tex2D(InputSampler,float2(iMouse.x + pixX,iMouse.y));

	col += tex2D(InputSampler,iMouse - float2(pixX,-pixY));      // jwrl: changed from float2(iMouse.x - pixX,iMouse.y + pixY) (simplified mathematics)
	col += tex2D(InputSampler,float2(iMouse.x,iMouse.y + pixY));
	col += tex2D(InputSampler,iMouse + float2(pixX,pixY));       // jwrl: changed from float2(iMouse.x + pixX,iMouse.y + pixY) (simplified mathematics)

	col = col / 9.0;
	float cout = dot(col.rgb,float3(0.33333,0.33334,0.33333));

	return cout;
}


float regShape(float2 p, int N)
{
 float f;


float a=atan2(p.x,p.y)+.2;
float b=6.28319/float(N);
f=smoothstep(.5,.51, cos(floor(.5+a/b)*b-a)*length(p.xy));


    return f;
}
float3 circle(float2 p, float size, float decay, float3 color,float3 color2, float dist, float2 mouse, float i)
{
	float complex = ceil(COMPLEX);
	p = p * (1.0 - ZOOM);
	float po = POINTS / 10.0;
	int blades = BLADES + 5;


    //l is used for making rings.I get the length and pass it through a sinwave
    //but I also use a pow function. pow function + sin function , from 0 and up, = a pulse, at least
    //if you return the max of that and 0.0.

    float l = length(p + mouse*(dist*4.))+size/2.;

    //l2 is used in the rings as well...somehow...
    float l2 = length(p + mouse*(dist*4.))+size/3.;

    ///these are circles, big, rings, and  tiny respectively
    float c = max(00.01-pow(length(p + mouse*dist), size*1.4), 0.0)*50.;
    float c1 = max(0.001-pow(l-0.3, 1./40.)+sin(l*30.), 0.0)*3.;
    float c2 =  max(0.04/pow(length(p-mouse*dist/2. + po)*1., 1.), 0.0)/20.;
    float s = max(00.01-pow(regShape(p*5. + mouse*dist*5. + SHUTTER, blades) , 1.), 0.0)*5.;

   	color = 0.5+0.5*sin(color);
    color = cos(float3(0.44, .24, .2)*8. + dist*4.)*0.5+.5;
 	float3 f = c*color ;
    f += c1*color;

    f += c2*color;
    f +=  s*color;
/*
jwrl: Ensured that this returns a valid result in both Cg and D3D by replacing this
	if (i > complex) return float3(0,0,0);
    else return f - 0.01;
*/
   return (i > complex) ? 0.0.xxx : f - 0.01.xxx;
}

float sun(float2 p, float2 mouse)
{
 float f;

    float2 sunp = p+mouse;
    float sun = 1.0-length(sunp)*8.;
    return f;
}

float4 mainImage( float2 fragCoord : TEXCOORD1) : COLOR
{
	float rays = ceil(RAYS);
	float v = vary();
	if (v < THRESH) v = 0.0;
	if (!AFFECT) v = 1.0;
	float affect = saturate(GLINT - (1.0 - v));
/*
jwrl:  The alpha channel is never used in this shader, so the declaration of orig has been changed to a float3.
       iResolution is no longer needed - see below.
       fragColor is no longer needed - see the shader return code at the end.
       iMouse is declared, used once then immediately discarded.  It has been removed.
       The way that Cg handles float2 with float addition or subtraction differs from the way that D3D does and
       would have caused problems in the initialisation of uv if the float wasn't swizzled to a float2.
       The float2 arithmetic problem has been avoided with mm by rolling the original iMouse variable into it.
       When adjusting for the aspect ratio, in Lightworks _OutputAspectRatio can be used.

	float4 orig = tex2D(InputSampler, fragCoord);

	float2 iResolution = float2(_OutputWidth, _OutputHeight);
	float4 fragColor; 
	float2 uv = fragCoord.xy - 0.5;
    float2 iMouse = float2(CENTERX,1.0 - CENTERY);
    uv.x*=iResolution.x/iResolution.y;
    float2 mm = iMouse.xy - 0.5; ///iResolution.xy - 0.5
    mm.x *= iResolution.x/iResolution.y;
*/
    float3 orig = tex2D (InputSampler, fragCoord).rgb;

    float2 uv = fragCoord - 0.5.xx;
    float2 mm = float2 ((CENTERX - 0.5) * _OutputAspectRatio, 0.5 - CENTERY);

    uv.x *= _OutputAspectRatio;

    float3 circColor = float3(0.9, 0.2, 0.1);
    float3 circColor2 = float3(0.3, 0.1, 0.5);

    //now to make the sky not black
/*
jwrl: Originally this had the following code which would have partially worked, but was resource hungry for no good result.

    float3 color = (lerp(float3(0.0, 0.0, 0.00)/1.0, float3(0.0, 0.0, 0.0), uv.y)*3.-0.52*sin(CTIME/0.4)*0.1+0.2) * SCATTER;

Dividing zero by one gives zero, so mixing between 0 and 0 will also give 0.  Multiplying that zero by three does nothing either.
I suspect that uv.y was intended to provide a vertical graduation to the sky but at no stage could ever have done anything so it
has now been removed from the equation.

Finally, subtracting a float from a float3 will give different results in D3D and Cg and should be avoided.  Working with floats
then swizzling the result to a float3 is more predictable.
*/
    float3 color = (0.0 - 0.52 * sin (CTIME / 0.4) * 0.1 + 0.2).xxx * SCATTER;

    //this calls the function which adds three circle types every time through the loop based on parameters I
    //got by trying things out. rnd i*2000. and rnd i*20 are just to help randomize things more
/*
jwrl: Implementing a loop with an integer rather than a float is more efficient and should execute with lower overhead.

    for(float i=0.;i<10.;i++){
        color += circle(uv, pow(rnd(i*2000.)*1.0, 2.)+1.41, 0.0, circColor+i , circColor2+i, rnd(i*20.)*3.+0.2-.5, mm, i); //0.8 back to 0.2
    }

Casting the integer in the new loop to a float has been done only where absolutely necessary, and it's also swizzled where that's needed.

Finally + 0.2 - 0.5 has been simplified to - 0.3.
*/
    for (int i = 0; i < 10; i++) {
        color += circle (uv, pow (rnd (i * 2000.0), 2.0) + 1.41, 0.0, circColor + float (i).xxx, circColor2 + float (i).xxx, rnd (i * 20.0) * 3.0 - 0.3, mm, float (i));
    }

    //get angle and length of the sun (uv - mouse)
        float a = atan2(uv.y-mm.y, uv.x-mm.x);
		float l = length(uv-mm); l = pow(l,.1);
		float n = noise2(float2((a-CTIME/9.0)*16.0,l*32.0));

    float bright = 0.1;//+0.1/1/3.;//add brightness based on how the sun moves so that it is brightest
    //when it is lined up with the center

    //add the sun with the frill things
	color += (1.0 / (length (uv - mm) * 16.0 + 1.0) * affect).xxx; // jwrl: changed from (1.0/(length(uv-mm)*16.0+1.0) * affect) for float3 arithmetic
	color += (color*(sin((a+CTIME/18.0 + noise1(abs(a)+n/2.0)*2.0)*rays)*.1+l*.1+.8)) * affect;

    //add another sun in the middle (to make it brighter)  with the color I want, and bright as the numerator.

    color += ((max(bright/pow(length(uv-mm)*4., 1./2.), 0.0)*4.)*float3(0.2, 0.21, 0.3)*4.) * affect;

    //    * (0.5+.5*sin(float3(0.4, 0.2, 0.1) + float3(a*2., 00., a*3.)+1.3));

    //multiply by the exponetial e^x ? of 1.0-length which kind of masks the brightness more so that
    //there is a sharper roll of of the light decay from the sun.
	color*= exp(1.0-length(uv-mm))/5.;
/*
jwrl: This was originally of the form shown below.  However only the first three elements of fragColor were ever used, making it identical to color in
this context.  Additionally orig no longer needs to be a float4, since the alpha channel is not used either.  This makes the exit code very much simpler.

	fragColor = float4(color,0.5);
	return float4(saturate(orig.rgb + ((fragColor.rgb * AMOUNT) * v)),1.0);
*/
	return float4 (saturate (orig + (color * v * AMOUNT)), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Scape
{
   pass Pass1
   {
      PixelShader = compile PROFILE mainImage ();
   }
}
