#version 460

layout(location = 0) in vec3 in_position1;
layout(location = 1) in vec3 in_tangent1;
layout (location = 2) in vec4 in_color1;

layout(location = 3) in uint in_id;

layout(location = 4) in vec3 in_position2;
layout(location = 5) in vec3 in_tangent2;
layout(location = 6) in vec4 in_color2;

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
uniform float delta;


void main()
{
	vec3 in_position = in_position1 * (1 - delta) + in_position2 * delta;
	vec3 in_tangent = normalize(in_tangent1 * (1 - delta) + in_tangent2 * delta);
	vec4 in_color = in_color1 * (1 - delta) + in_color2 * delta;

	vec4 spos=mvp_matrix*vec4(in_position,1.0f);
	vs_out.scr_pos= spos;
	vs_out.real_pos = in_position;
	vs_out.color=in_color;
	vs_out.tangent=in_tangent;
	
	//point---->eye
	vec3 ep=normalize(eye_pos-in_position);
	vec3 dir=cross(ep,in_tangent);
	vs_out.normal=dir;
	vs_out.c_normal=cross(in_tangent,dir);
	
	vs_out.pointID = in_id;
}
