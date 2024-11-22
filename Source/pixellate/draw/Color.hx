package pixellate.draw;

typedef RGBA = { r:Float, g:Float, b:Float, a:Float }

class Color {
	public static final TRANSPARENT:RGBA = { r:0, g:0, b:0, a: 0 };
	public static final BLACK:RGBA = { r:0, g:0, b:0, a: 1 };

	public overload extern inline static function rgba(r:Float, g:Float, b:Float, a:Float = 1.0):RGBA {
		return { r:r, g:g, b:b, a:a };
	}

	public overload extern inline static function rgba(r:Int, g:Int, b:Int, a:Float = 1.0):RGBA {
		return rgba(r/255, g/255, b/255, a);
	}

	public overload extern inline static function rgba(rgba:Int):RGBA {
		var r:Float = (rgba >> 16) & 0xFF;
		var g:Float = (rgba >> 8) & 0xFF;
		var b:Float = (rgba >> 0) & 0xFF;
		var a:Float = (rgba >> 24) & 0xFF;
		return { r:r/255, g:g/255, b:b/255, a:a/255 };
	}


	public var fill:RGBA = TRANSPARENT;
	public var stroke:RGBA = TRANSPARENT;

	public function new(options: { ?fill:RGBA, ?stroke:RGBA }) {
		if (options.fill != null) { this.fill = options.fill; }
		if (options.stroke != null) { this.stroke = options.stroke; }
	}
}