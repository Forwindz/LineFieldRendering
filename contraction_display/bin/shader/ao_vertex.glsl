#version 460

//light info
layout(location = 0) in vec2 position; 
//out vec2 textCoord;
void main(void) 
{ 
	gl_Position = vec4(position, -0.0, 1.0); 
	//textCoord = vec2(position.x + 1, -position.y + 1)*512.0f;
}
