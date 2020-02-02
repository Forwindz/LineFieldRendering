#version 460

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 in_tangent;
layout (location = 2) in vec4 in_color;
layout (location = 3) in uint in_pointID;

out VS_OUT {
    vec3 tangent;	//direction 3d, normalized
	vec4 color;		//line color
	vec3 normal;	//at the edge of line, normal, normalized
	vec3 c_normal;	//at the center of line, normal, normalized
	vec3 real_pos;
	vec4 scr_pos;
	flat uint pointID;
} vs_out;

uniform mat4 mvp_matrix;
uniform vec3 eye_pos;


void main()
{
	vec4 spos=mvp_matrix*vec4(position,1.0f);
	vs_out.scr_pos= spos;
	vs_out.real_pos = position;
	vs_out.color=in_color;
	vs_out.tangent=in_tangent;
	
	//point---->eye
	vec3 ep=normalize(eye_pos-position);
	vec3 dir=cross(ep,in_tangent);
	vs_out.normal=dir;
	vs_out.c_normal=cross(dir,in_tangent);
	vs_out.pointID = in_pointID;
}
