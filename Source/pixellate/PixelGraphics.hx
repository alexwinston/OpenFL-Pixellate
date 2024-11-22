package pixellate;

import lime.graphics.WebGLRenderContext;
import openfl.display3D.Context3D;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import pixellate.draw.Drawable;

class PixelGraphics extends Bitmap {
	private var pixellateShader:PixellateShader;

	public function new(ctx3d:Context3D, gl:WebGLRenderContext, bmpData:BitmapData, scale:Int = 1) {
		super(bmpData);
		this.scaleX = scale;
		this.scaleY = scale;
		this.pixellateShader = new PixellateShader(ctx3d, gl, bmpData);
	}

	public function pixellate(drawable:Drawable, copy:Bool = true):PixellateLayer {
		return this.pixellateShader.buffer(drawable, copy);
	}

	private override function __enterFrame(deltaTime:Int):Void {
		super.__enterFrame(deltaTime);
		this.render();
	}

	public function render():Void {
		this.invalidate();
		this.pixellateShader.composite();
	}

	public function clear(buffers:Bool = false):Void {
		this.pixellateShader.clear(buffers);
	}
}