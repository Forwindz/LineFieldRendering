#version 460

uniform sampler2DMS depthTex;

in GS_OUT{
	vec3 tangent;
	vec4 color;
	vec3 normal;
	vec3 c_normal;
	vec3 real_pos;
	flat uint pointID;
	float sign;
} fs_in;

layout(location=3)out vec4 out_color;
layout(location=1)out vec3 out_normal;
layout(location=2)out vec3 out_pos;
layout(location = 0)out vec4 out_pointID;

void main()
{
	//compute normal, add tiny vec3 to avoid (0,0,0)
	out_normal = vec3(0.5f)+ 0.5f*
		normalize(fs_in.normal*sin(fs_in.sign) + fs_in.c_normal*cos(fs_in.sign) + vec3(0.00000001f, 0.00000001f, 0.00000001f));
	//compute light & color
	out_color =  fs_in.color;
	//out_color = vec4(0.2f, 0.1f, 1, 0.5f);
	//out_pos = fs_in.real_pos;
	out_pos = fs_in.real_pos;
	out_pointID = vec4(
		((fs_in.pointID / 1000000 % 100)) / 100.0f,
		((fs_in.pointID / 10000 % 100)) / 100.0f,
		((fs_in.pointID / 100 % 100)) / 100.0f,
		((fs_in.pointID % 100)) / 100.0f);
}