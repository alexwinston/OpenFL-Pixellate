package pixellate;

import openfl.display3D.Context3D;
import pixellate.draw.Drawable;
import lime.graphics.WebGLRenderContext;
import openfl.display.BitmapData;
import lime.graphics.opengl.*;
import lime.utils.*;
import lime.math.Vector2;

class PixellateShader {
	private var framebuffer : GLFramebuffer;

    private var bmpData:BitmapData;
    private var texture:GLTexture;

    private var width:Int = 0;
    private var height:Int = 0;
	private var buffers:Map<Drawable,GLBuffer> = new Map();
    private var layers:Array<PixellateLayer> = [];

	private var gl:WebGLRenderContext;

	private var program:GLProgram;
	private var vertexAttribute:Int;
	private var colorUniform:GLUniformLocation;
	private var sizeUniform:GLUniformLocation;
	private var originUniform:GLUniformLocation;
	private var translationUniform:GLUniformLocation;
	private var rotationUniform:GLUniformLocation;
	private var scaleUniform:GLUniformLocation;
	private var shearUniform:GLUniformLocation;

	public function new(ctx3d:Context3D, gl:WebGLRenderContext, bmpData:BitmapData):Void {
		this.gl = gl;
        this.bmpData = bmpData;
        this.texture = @:privateAccess bmpData.getTexture(ctx3d).__textureID;
        this.width = bmpData.width;
        this.height = bmpData.height;

        this.framebuffer = gl.createFramebuffer ();
        this.gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffer);

        var vertexShader = #if !desktop "precision highp float; " + #end
			"
			attribute vec2 aPosition;

			uniform vec4 uColor;
			uniform vec2 uSize;
			uniform vec2 uOrigin;
			uniform vec2 uTranslation;
			uniform vec2 uScale;
			uniform vec2 uShear;
			uniform float uRotation;

			varying vec4 vColor;

			vec2 rotate(vec2 v, float a) {
				float s = sin(a);
				float c = cos(a);
				mat2 m = mat2(c, s, -s, c);
				return m * v;
			}

			void main (void) {
				vColor = vec4(uColor.r, uColor.g, uColor.b, uColor.a);

				// Scale the positon
				vec2 scaledPosition = aPosition * uScale;

				// Shear the position
				vec2 shearedPosition = mat2(1, uShear.y, uShear.x, 1) * scaledPosition;

				// Rotate the position at the origin
				shearedPosition = shearedPosition - uOrigin;
				vec2 rotatedPosition = rotate(shearedPosition, uRotation);
				rotatedPosition = rotatedPosition + uOrigin;

				// Translate the position at the origin
				vec2 translatedPosition = rotatedPosition + uTranslation - uOrigin;

				// Convert the position from pixels to 0.0 to 1.0
				vec2 zeroToOne = translatedPosition / uSize;
				// Convert from 0->1 to 0->2
				vec2 zeroToTwo = zeroToOne * 2.0;
				// Convert from 0->2 to -1->+1 (clip space)
				vec2 clipSpace = zeroToTwo - 1.0;

				gl_Position = vec4(clipSpace * vec2(1, 1), 0, 1);
				gl_PointSize = 1.0;
			}";


		var fragmentShader = #if !desktop "precision highp float; " + #end
		"
		varying vec4 vColor;
		void main(void) {
			gl_FragColor = vColor;
		}	
		";

		// this.gl.enable(GL.VERTEX_PROGRAM_POINT_SIZE);
		this.program = GLProgram.fromSources(gl, vertexShader, fragmentShader);

		this.vertexAttribute = gl.getAttribLocation(program, "aPosition");

		this.colorUniform = gl.getUniformLocation(program, "uColor");
		this.sizeUniform = gl.getUniformLocation(program, "uSize");
		this.originUniform = gl.getUniformLocation(program, "uOrigin");
		// https://webgl2fundamentals.org/webgl/lessons/webgl-2d-translation.html
		this.translationUniform = gl.getUniformLocation(program, "uTranslation");
		// https://webgl2fundamentals.org/webgl/lessons/webgl-2d-rotation.html
		this.rotationUniform = gl.getUniformLocation(program, "uRotation");
		// https://webgl2fundamentals.org/webgl/lessons/webgl-2d-scale.html
		this.scaleUniform = gl.getUniformLocation(program, "uScale");
		this.shearUniform = gl.getUniformLocation(program, "uShear");

        // Copy VBO to Texture https://community.openfl.org/t/access-texture-of-bitmapdata-directly-cpp/8477/3
        this.gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
	}

	public function buffer(drawable:Drawable, copy:Bool = true):PixellateLayer {
		var buffer:GLBuffer = this.buffers.get(drawable);
		if (buffer == null) {
			buffer = gl.createBuffer();
			gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
			gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(drawable.points), gl.STATIC_DRAW);

			this.buffers.set(drawable, buffer);
		}

       	var layer = new PixellateLayer(gl, copy ? drawable.copy() : drawable, buffer, this.width, this.height);
		this.layers.push(layer);

        return layer;
	}

	public function composite():Void {
		var p = gl.getParameter(gl.CURRENT_PROGRAM);
		
        gl.useProgram(this.program);
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);

		gl.viewport(0, 0, this.width, this.height);
		gl.clearColor(0.0, 0.0, 0.0, 0.0);
		gl.clear(gl.COLOR_BUFFER_BIT);// | gl.DEPTH_BUFFER_BIT);

		gl.enable(gl.BLEND);
		gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

		gl.uniform2f(sizeUniform, this.width, this.height);

		for (layer in this.layers) {
            gl.uniform2f(originUniform, layer.origin.x, layer.origin.y);
            gl.uniform2f(translationUniform, layer.translate.x, layer.translate.y);
            gl.uniform1f(rotationUniform, layer.rotation * Math.PI/180);
            gl.uniform2f(scaleUniform, layer.scale.x, layer.scale.y);
            gl.uniform2f(shearUniform, layer.shear.x, layer.shear.y);

			gl.bindBuffer(gl.ARRAY_BUFFER, layer.positions);

			gl.vertexAttribPointer(vertexAttribute, 2, gl.FLOAT, false, 2 * Float32Array.BYTES_PER_ELEMENT, 0);
			// gl.enableVertexAttribArray(vertexAttribute); // ???

			for (command in layer.drawable.commands) {
				gl.uniform4f(colorUniform, command.color.r, command.color.g, command.color.b, command.color.a);
            	gl.drawArrays(command.mode, command.i0, command.i1);
			}
		}
		gl.bindFramebuffer (gl.FRAMEBUFFER, null);
		
		gl.useProgram(p);
	}

	public function clear(buffers:Bool = false) {
		if (buffers) { this.buffers.clear(); }
		untyped this.layers.length = 0;
	}

	public function dispose() : Void {
		gl.deleteFramebuffer (this.framebuffer);
		gl.deleteProgram(this.program);
	}
}
