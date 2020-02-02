#version 460

//light info
struct AmbientLight
{
	float intensity;
	vec3 color;
};

struct DirectLight
{
	float intensity;
	vec3 color;
	vec3 direct;
};

struct SpecularLight
{
	float power, intensity;
};

struct PointLight
{
	vec3 pos;
	vec3 color;
	float intensity;
};

struct LightInfo
{
	AmbientLight    al;
	DirectLight     dl;
	SpecularLight   sl;
};
//end light definition

//https://blog.csdn.net/panda1234lee/article/details/71326063
const unsigned int SampleRate = 16;
layout(binding = 4) uniform SampleData
{
	ivec4 sd[16];
}sampleData;
//vec2 sd[16];

uniform sampler2DMS depthTex;
uniform sampler2DMS normalTex;
uniform sampler2DMS colorTex;
uniform sampler2DMS posTex;

uniform vec3 eyePos;
uniform LightInfo li;

const float PI = 3.1415926535f;
const float SR_average = 1.0f / float(SampleRate);
const int MSAASample = 4;
const float MSAAAverage = 1.0f / MSAASample;

//in vec2 textCoord;
ivec2 curPos;

float fx(const float x)
{
	return 3 * pow(x, 2) - 2 * pow(x, 3);
}

out vec3 out_color;
/*
//NO MSAA 
float ao_sample_test()
{
	float ans = 0;
	const float curDepth = texture(depthTex, textCoord.xy).x;
	for (int i = 0; i < SampleRate; ++i)
	{
		const vec2 samplePos = vec2(sampleData.sd[i].x + textCoord.x,
			sampleData.sd[i].y + textCoord.y);
		const float sampleDepth = texture(depthTex, samplePos).x;
		ans += step(curDepth, sampleDepth)//if not visiable return 0
			*(1 - fx(curDepth - sampleDepth));
	}
	return clamp(ans * SR_average, 0, 1);
}*/
//MSAA
float ao_sample_test(const int i)
{
	float ans = 0;
	const float curDepth = texelFetch(depthTex, curPos,i).x;
	for (int i = 0; i < SampleRate; ++i)
	{
		const ivec2 samplePos = ivec2(sampleData.sd[i].x + curPos.x,
			sampleData.sd[i].y + curPos.y);
		const float sampleDepth = texelFetch(depthTex, samplePos, sampleData.sd[i].z).x;
		ans += step(curDepth, sampleDepth)//if not visiable return 0
			*(1 - fx(curDepth - sampleDepth));
	}
	return clamp(ans * SR_average, 0, 1);
}

vec3 computeLight(const vec3 normal, const vec3 worldPos, const float aof)
{
	//ambient
	vec3 totalColor = li.al.intensity*li.al.color*aof;
	//direct
	const float dlv = dot(normal, li.dl.direct)*li.dl.intensity;
	totalColor += step(0,dlv) * dlv * li.dl.color;//if>0, then add, else add 0
	//specular
	
	const vec3 eyeToP = normalize(eyePos - worldPos);//normalize(normalize(eyePos - worldPos) + li.dl.direct);
	const vec3 ref = normalize(reflect(li.dl.direct, normal));
	const float spower = dot(eyeToP, ref);
	if(spower>0)
		totalColor += vec3(li.dl.color * li.sl.intensity * pow(spower, li.sl.power));
		
	return totalColor;
}

void main()
{
	//float precious issues, we need add extra tiny decimal to prevent strange things happen
	curPos = ivec2(gl_FragCoord.xy);// ivec2(round(textCoord.x + 0.0001f), round(textCoord.y + 0.0001f));

	vec3 total_color = vec3(0);
	float ao_factor = ao_sample_test(gl_SampleID);
	vec3 normal = texelFetch(normalTex, curPos.xy, gl_SampleID).xyz*2.0f - vec3(1.0f);
	vec4 color = texelFetch(colorTex, curPos.xy, gl_SampleID).xyzw;
	vec3 pos = texelFetch(posTex, curPos.xy, gl_SampleID).xyz;
	float depthVal = texelFetch(depthTex, curPos.xy, gl_SampleID).x;
	if (length(pos) < 0.0000001f)
		total_color += vec3(1);
	else
		total_color += computeLight(normal, pos, ao_factor) * color.xyz;

	out_color = total_color;
}
