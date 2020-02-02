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

uniform vec3 eye_pos;
uniform LightInfo li;

uniform sampler2D aoFactor;

layout(binding = 0, r32ui)		uniform					uimage2DMS		uHeadPointer;
layout(binding = 1, rgba32ui)	uniform		writeonly	uimageBuffer	uListContent;
layout(binding = 2, offset = 0) uniform					atomic_uint		uListCounter;

in GS_OUT{
	vec3 tangent;
	vec4 color;
	vec3 normal;
	vec3 c_normal;
	vec3 real_pos;
	float sign;
	flat uint segID;
} fs_in;

vec3 computeLight(const vec3 normal, const vec3 worldPos,const float aof)
{
	//ambient
	vec3 totalColor = li.al.intensity*li.al.color*aof;
	//direct
	const float dlv = dot(normal, li.dl.direct)*li.dl.intensity;
	totalColor += step(0, dlv) * dlv * li.dl.color;//if>0, then add, else add 0
	if (dlv > 0)
		totalColor += dlv * li.dl.color;
	//specular

	const vec3 eyeToP = normalize(eye_pos - worldPos);
	const vec3 ref = normalize(reflect(-li.dl.direct, normal));
	const float spower = dot(eyeToP, ref);
	if (spower > 0)
		totalColor += vec3(li.dl.color * li.sl.intensity * pow(spower, li.sl.power));

	return totalColor;
}

//out vec3 out_color;

void main()
{
	//compute normal
	vec3 realNormal = normalize(fs_in.normal*sin(fs_in.sign) + fs_in.c_normal*cos(fs_in.sign) 
		+ vec3(0.00000001f, 0.00000001f, 0.00000001f));
	//compute color
	vec3 realColor = computeLight(realNormal, fs_in.real_pos, texture(aoFactor,gl_FragCoord.xy).x)*fs_in.color.xyz;

	//create list
	const uint listID = atomicCounterIncrement(uListCounter);
	uint oldHead = imageAtomicExchange(uHeadPointer, ivec2(gl_FragCoord.xy), gl_SampleID, uint(listID));

	imageStore(uListContent, int(listID), uvec4(
		floatBitsToUint(gl_FragCoord.z),
		packUnorm4x8(vec4(realColor, fs_in.color.w)),
		fs_in.segID,
		oldHead
	));
	//out_color = realColor;
}