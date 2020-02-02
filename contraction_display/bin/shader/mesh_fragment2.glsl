#version 460

in VS_OUT{
	vec3 normal;
	vec3 real_pos;
	vec4 color;
	flat uint pointID;
} fs_in;

layout(location=3)out vec4 out_color;
layout(location=1)out vec3 out_normal;
layout(location=2)out vec3 out_pos;
layout(location = 0)out vec4 out_pointID;

void main()
{
	out_normal = fs_in.normal;
	out_color =  fs_in.color;
	out_pos = fs_in.real_pos;
	out_pointID = vec4(
		1.0f/100.0f,
		((fs_in.pointID / 10000 % 100)) / 100.0f,
		((fs_in.pointID / 100 % 100)) / 100.0f,
		((fs_in.pointID % 100)) / 100.0f);
}