//
//  ImageShaders.metal
//  Metal2D
//
//  Created by Kaz Yoshikawa on 12/22/15.
//
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
	packed_float4 position [[ attribute(0) ]];
	packed_float2 texcoords [[ attribute(1) ]];
};

struct VertexOut {
	float4 position [[ position ]];
	float2 texcoords;
};

struct VertexInOut {
	float4 position [[ position ]];
};

struct Uniforms {
	float4x4 modelViewProjectionMatrix;
};

vertex VertexOut image_vertex(
							  device VertexIn * vertices [[ buffer(0) ]],
							  constant Uniforms & uniforms [[ buffer(1) ]],
							  uint vid [[ vertex_id ]]
							  ) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
	outVertex.position = uniforms.modelViewProjectionMatrix * float4(inVertex.position);
	outVertex.texcoords = inVertex.texcoords;
	return outVertex;
}

fragment float4 image_fragment(
							   VertexOut vertexIn [[ stage_in ]],
							   constant Uniforms & uniforms [[ buffer(0) ]],
							   constant float4* color [[ buffer(2) ]],
							   texture2d<float, access::sample> colorTexture [[ texture(0) ]],
							   sampler colorSampler [[ sampler(0) ]]
							   ) {
	return  float4(colorTexture.sample(colorSampler, vertexIn.texcoords).rgba) * color[0];
}



vertex VertexInOut line_vertex(uint vid [[ vertex_id ]],
							   constant packed_float4* position  [[ buffer(0) ]],
							   constant Uniforms & uniforms [[ buffer(1) ]])
{
	VertexInOut outVertex;
	
	outVertex.position = uniforms.modelViewProjectionMatrix * float4(position[vid]);
	
	return outVertex;
};

fragment half4 line_fragment(VertexInOut inFrag [[stage_in]])
{
	return half4(1, 1, 1, 1);
};
