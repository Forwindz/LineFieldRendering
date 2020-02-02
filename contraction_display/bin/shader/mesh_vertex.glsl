#version 460

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec4 in_color;
layout(location = 3) in uint in_id;
out VS_OUT {
	vec3 normal;
	vec3 real_pos;
	vec4 color;
	flat uint pointID;
} vs_out;

uniform mat4 mvp_matrix;


void main()
{
	vec4 spos=mvp_matrix*vec4(in_position,1.0f);
	gl_Position = spos;
	vs_out.real_pos = in_position;
	vs_out.pointID = in_id;
	vs_out.color=in_color;
	vs_out.normal = -in_normal;
}
