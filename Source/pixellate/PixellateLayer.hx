package pixellate;

import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.math.Vector2;
import openfl.geom.Point;
import pixellate.draw.Drawable;

class PixellateLayer {
	public var width:Int;
	public var height:Int;
	public var positions:GLBuffer;
	public var drawable:Drawable;
	// public var color:RGBA = Color.BLACK;
	public var origin:Point = new Point();
	// https://www.sector12games.com/skewshear-vertex-shader/
	public var shear:Vector2 = new Vector2();
	public var translate:Vector2 = new Vector2();
	public var scale:Vector2 = new Vector2(1,1);
	public var rotation:Float = 0.0;

	public var gl:WebGLRenderContext;

	public function new (webgl:WebGLRenderContext, drawable:Drawable, positions:GLBuffer, width:Int, height:Int) {
		this.gl = webgl;
        this.positions = positions;
		this.drawable = drawable;
		this.width = width;
		this.height = height;
	}

	public function dispose() : Void {
		gl.deleteBuffer(this.positions);
	}
}