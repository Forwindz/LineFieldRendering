#version 460

const unsigned int SampleRate = 16;
layout(binding = 4) uniform SampleData
{
	ivec4 sd[16];
}sampleData;

uniform sampler2DMS depthTex;

const float PI = 3.1415926535f;
const float SR_average = 1.0f / float(SampleRate);

in vec2 textCoord;
layout(location = 0) out float aoFactor;
ivec2 curPos;

float fx(const float x)
{
	return 3 * pow(x, 2) - 2 * pow(x, 3);
}

void main()
{
	//float precious issues, we need add extra tiny decimal to prevent strange things happen
	curPos = ivec2(round(textCoord.x+0.0001f),round(textCoord.y+0.0001f));
	
	float ans = 0;
	const float curDepth = texelFetch(depthTex, curPos, gl_SampleID).x;
	for (int i = 0; i < SampleRate; ++i)
	{
		const ivec2 samplePos = ivec2(sampleData.sd[i].x + curPos.x,
			sampleData.sd[i].y + curPos.y);
		const float sampleDepth = texelFetch(depthTex, samplePos, sampleData.sd[i].z).x;
		ans += step(curDepth, sampleDepth)//if not visiable return 0
			*(1 - fx(curDepth - sampleDepth));
	}

	ans = clamp(ans*0.25f, 0, 1);
	aoFactor = ans;
}
