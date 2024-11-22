package pixellate.draw;

import pixellate.draw.Color;

using Std;

private class Point {
	public var x : Float;
	public var y : Float;

	public inline function new(x, y) {
		this.x = x;
		this.y = y;
	}
}

class Shapes {
	public var points : Array<Point>;
    public var drawable:Drawable;
	var pindex : Int;
	var fillColor:RGBA;
	var strokeColor:RGBA;
	var lineSize : Float;
	var doFill : Bool;

	public var bevel = 0; // 1 = Always beveled

	public function new() {
		this.points = [];
		this.pindex = 0;
		this.lineSize = 0;
		this.drawable = new Drawable();
	}

	overload extern inline public function line(color:RGBA, x1:Int, y1:Int, x2:Int, y2:Int, width:Int = 1) {
		this.lineStyle(width, color);
		this.moveTo(x1,y1);
		this.lineTo(x2,y2);
		this.endFill();
	}

	overload extern inline public function lines(color:RGBA, points:Array<Int>, width:Int = 1, closed:Bool = false) {
		// this.beginFill ???
		this.lineStyle(width, color);
		this.moveTo(points[0],points[1]);
		var i = 2; while(i < points.length) {
			this.lineTo(points[i++],points[i++]);
		}
		if (closed) {
			this.lineTo(points[0], points[1]);
		}
		this.endFill();
	}

	overload extern inline public function polygon(color:RGBA, points:Array<Int>, width:Int = 0) {
		this.lines(color, points, width, true);
	}

	overload extern inline public function rect(color:Color, x:Int, y:Int, w:Int, h:Int, width:Int = 0, radius:Int = 0):Drawable {
		this.beginFill(color.fill);
		if (width > 0) {
			this.lineStyle(width, color.stroke);
		}
		if (radius == 0) {
			this.drawRect(x, y, w, h);
		} else {
			this.drawRoundedRect(x, y, w, h, radius);
		}
		this.endFill();

		return this.drawable;
	}

	overload extern inline public function circle(color:Color, cx:Float, cy:Float, radius:Int, width:Int = 0) {
		this.beginFill(color.fill);
		if (width > 0) {
			this.lineStyle(width, color.stroke);
		}
		this.drawCircle(cx, cy, radius);
		this.endFill();
	}

	overload extern inline public function ellipse(color:Color, cx:Float, cy:Float, radiusX:Float, radiusY:Float, width:Int = 0, rotation:Float = 0) {
		this.beginFill(color.fill);
		if (width > 0) {
			this.lineStyle(width, color.stroke);
		}
		this.drawEllipse(cx, cy, radiusX, radiusY, rotation);
		this.endFill();
	}

	overload extern inline public function pie(color:Color, cx:Float, cy:Float, radius:Float, radiusInner:Float, angleStart:Float, angleLength:Float, width:Int = 0) {
		this.beginFill(color.fill);
		if (width > 0) {
			this.lineStyle(width, color.stroke);
		}
		this.drawPieInner(cx, cy, radius, radiusInner, angleStart, angleLength);
		this.endFill();
	}

	overload extern inline public function arc(color:Color, cx:Float, cy:Float, radius:Float, angleStart:Float, angleLength:Float, width:Int = 0) {
		this.beginFill(color.fill);
		if (width > 0) {
			this.lineStyle(width, color.stroke);
		}
		this.drawArc(cx, cy, radius, angleStart, angleLength);
		this.endFill();
	}

	private inline function add( x : Float, y : Float) {
		this.drawable.points.push(x);
		this.drawable.points.push(y);
	}

	/**
		Clears the Graphics contents.
	**/
	public function clear() {
		untyped this.points.length = 0;
		this.pindex = 0;
		this.lineSize = 0;
		this.drawable = new Drawable();
	}

	// TODO http://web.archive.org/web/20200815155854/http://ncannasse.fr/blog/fast_inverse_square_root
	public static inline function invSqrt( f : Float ) {
		return 1. / std.Math.sqrt(f);
	}

	function flushLine( start:Int ) {
		var pts = points;
		var last = pts.length - 1;
		var prev = pts[last];
		var p = pts[0];

		var closed = p.x == prev.x && p.y == prev.y;
		var count = pts.length;
		if( !closed) {
			var prevLast = pts[last - 1];
			if( prevLast == null ) prevLast = p;
			var gp = new Point(prev.x * 2 - prevLast.x, prev.y * 2 - prevLast.y);
			pts.push(gp);
			var pNext = pts[1];
			if( pNext == null ) pNext = p;
			var gp = new Point(p.x * 2 - pNext.x, p.y * 2 - pNext.y);
			prev = gp;
		} else if( p != prev ) {
			count--;
			last--;
			prev = pts[last];
		}

		for( i in 0...count ) {
			var next = pts[(i + 1) % pts.length];

			var nx1 = prev.y - p.y;
			if (nx1 == 0) { nx1 = 0.0; }
			var ny1 = p.x - prev.x;
			if (ny1 == 0) { ny1 = 0.0; }
			var ns1 = invSqrt(nx1 * nx1 + ny1 * ny1);
			if (!Math.isFinite(ns1)) { ns1 = 0.0; }

			var nx2 = p.y - next.y;
			var ny2 = next.x - p.x;
			var ns2 = invSqrt(nx2 * nx2 + ny2 * ny2);
			if (!Math.isFinite(ns2)) { ns2 = 0.0; }

			var nx = nx1 * ns1 + nx2 * ns2;
			var ny = ny1 * ns1 + ny2 * ns2;
			var ns = invSqrt(nx * nx + ny * ny);
			if (!Math.isFinite(ns)) { ns = 0.0; }

			nx *= ns;
			ny *= ns;

			var size = nx * nx1 * ns1 + ny * ny1 * ns1; // N.N1
			if (size == 0 || !Math.isFinite(size)) { size = 1.0; }

			var d = lineSize * 0.5 / size;
			if (!Math.isFinite(d)) { d = 0.0; }
			nx *= d;
			ny *= d;

			// TODO https://wwwtyro.net/2019/11/18/instanced-lines.html
			if(size > bevel) { // Currently size is always greater than bevel
				if (lineSize == 1) {
					add(p.x, p.y);
				} else {
					add(p.x + nx, p.y + ny);
					add(p.x - nx, p.y - ny);
				}

				if (i == count - 1 && closed) {
					add(drawable.points[start * 2], drawable.points[ start * 2 + 1]);
					add(drawable.points[start * 2 + 2], drawable.points[ start * 2 + 3]);
					pindex+=2;
				}
				
				pindex += (lineSize == 1 ? 1 : 2);
			} else {
				//miter?
				var n0x = next.x - p.x;
				var n0y = next.y - p.y;
				var sign = n0x * nx + n0y * ny;

				var nnx = -ny;
				var nny = nx;

				var size = nnx * nx1 * ns1 + nny * ny1 * ns1;
				var d = lineSize * 0.5 / size;
				if (!Math.isFinite(d)) { d = 0.0; }

				nnx *= d;
				nny *= d;

				if(sign > 0) {
					add(p.x + nx, p.y + ny);
					add(p.x - nnx, p.y - nny);
					add(p.x + nnx, p.y + nny);
				} else {
					add(p.x + nnx, p.y + nny);
					add(p.x - nx, p.y - ny);
					add(p.x - nnx, p.y - nny);
				}

				pindex += 3;
			}

			prev = p;
			p = next;
		}
	}

	function flushFill( i0:Int ) {
		if( points.length < 3 )
			return;

		var pts = points;
		var p0 = pts[0];
		var p1 = pts[pts.length - 1];
		var last = null;
		// Closed poly
		if( Math.abs(p0.x - p1.x) < 1e-9 && Math.abs(p0.y - p1.y) < 1e-9 )
			last = pts.pop();

		if( last != null )
			pts.push(last);
	}

	var fillPoints = 0;
	function flush() {
		if( doFill ) {
			if (fillPoints == 0) { return; }
			pindex += fillPoints;
			this.drawable.commands.push(
				new Command(Mode.TRIANGLE_FAN, this.fillColor, this.drawable.index, pindex - this.drawable.index));
			this.drawable.index = pindex;
		}
		if( this.lineSize > 0 ) {
			if( points.length == 0 ) { return; }
			flushLine(pindex);
			this.drawable.commands.push(
				new Command(this.lineSize == 1 ? Mode.LINE_STRIP : Mode.TRIANGLE_STRIP,
					this.strokeColor, this.drawable.index, pindex - this.drawable.index));
		}
		
		this.drawable.index = pindex;
        this.lineSize = 0;
		
		untyped points.length = 0;
		fillPoints = 0;
	}

	public function beginFill(?color:RGBA) {
		setColor(color);
		doFill = true;
	}

	public function lineStyle( size : Float = 0, ?color:RGBA) {
		this.lineSize = size;
		this.strokeColor = color;
	}

	public inline function moveTo(x,y) {
		flush();
		lineTo(x, y);
	}

	public function endFill() {
		flush();
		doFill = false;
	}

	public inline function setColor(color : RGBA) {
		this.fillColor = color;
	}

	/**
		Draws a rectangle with given parameters.
		@param x The rectangle top-left corner X position.
		@param y The rectangle top-left corner Y position.
		@param w The rectangle width.
		@param h The rectangle height.
	**/
	public function drawRect( x : Float, y : Float, w : Float, h : Float ) {
		flush();
		lineTo(x, y);
		lineTo(x + w, y);
		lineTo(x + w, y + h);
		lineTo(x, y + h);
		lineTo(x, y - (lineSize / 2) - 0.01);
		flush();
	}

	public static inline function degToRad( deg : Float) {
		return deg * Math.PI / 180.0;
	}

	/**
		Draws a rounded rectangle with given parameters.
		@param x The rectangle top-left corner X position.
		@param y The rectangle top-left corner Y position.
		@param w The rectangle width.
		@param h The rectangle height.
		@param radius Radius of the rectangle corners.
		@param segments Amount of segments used for corners. When `0` segment count calculated automatically.
	**/
	public function drawRoundedRect( x : Float, y : Float, w : Float, h : Float, radius : Float, segments = 0 ) {
		if (radius <= 0) {
			return drawRect(x, y, w, h);
		}
		x += radius;
		y += radius;
		w -= radius * 2;
		h -= radius * 2;
		var width = this.lineSize;
		flush();
		this.lineSize = width;

		if( segments == 0 )
			segments = Math.ceil(Math.abs(radius * degToRad(90) / 4));
		if( segments < 3 ) segments = 3;
		var angle = degToRad(90) / (segments - 1);
		inline function corner(x, y, angleStart) {
		for ( i in 0...segments) {
			var a = i * angle + degToRad(angleStart);
			lineTo(x + Math.cos(a) * radius, y + Math.sin(a) * radius);
		}
		}
		lineTo(x, y - radius);
		lineTo(x + w, y - radius);
		corner(x + w, y, 270);
		lineTo(x + w + radius, y + h);
		corner(x + w, y + h, 0);
		lineTo(x, y + h + radius);
		corner(x, y + h, 90);
		lineTo(x - radius, y);
		corner(x, y, 180);
		flush();
	}


	static var circlesCache:Map<Int, Array<Float>> = new Map();

	/**
		Draws a circle centered at given position.
		@param cx X center position of the circle.
		@param cy Y center position of the circle.
		@param radius Radius of the circle.
		@param segments Amount of segments used to draw the circle. When `0`, amount of segments calculated automatically.
	**/
	public function drawCircle( cx : Float, cy : Float, radius : Int, segments = 0 ) {
		var circle = circlesCache.get(radius);
		if (circle == null) {
			circle = [];

			if( segments == 0 )
				segments = Math.ceil(Math.abs(radius * 3.14 * 2));
			trace('segments: ' + segments);
			if( segments < 3 ) segments = 3;
			var angle = Math.PI * 2 / segments;
			for( i in 0...segments + 1 ) {
				var a = i * angle;
				var raX = Math.cos(a) * radius;
				var raY = Math.sin(a) * radius;
				lineTo(cx + raX, cy + raY);

				circle.push(raX);
				circle.push(raY);
			}
			circlesCache.set(radius, circle);
		} else {
			var i = 0; while (i < circle.length) {
				this.lineTo(cx + circle[i++], cy + circle[i++]);
			}
		}
	}

	/**
		Draws an ellipse centered at given position.
		@param cx X center position of the ellipse.
		@param cy Y center position of the ellipse.
		@param radiusX Horizontal radius of an ellipse.
		@param radiusY Vertical radius of an ellipse.
		@param rotationAngle Ellipse rotation in radians.
		@param segments Amount of segments used to draw an ellipse. When `0`, amount of segments calculated automatically.
	**/
	public function drawEllipse( cx : Float, cy : Float, radiusX : Float, radiusY : Float, rotationAngle : Float = 0, segments = 0 ) {
		flush();
		if( segments == 0 )
			segments = Math.ceil(Math.abs(radiusY * 3.14 * 2 / 4));
		if( segments < 3 ) segments = 3;
		var angle = Math.PI * 2 / segments;
		var x1, y1;
		for( i in 0...segments + 1 ) {
			var a = i * angle;
			x1 = Math.cos(a) * Math.cos(rotationAngle) * radiusX - Math.sin(a) * Math.sin(rotationAngle) * radiusY;
			y1 = Math.cos(rotationAngle) * Math.sin(a) * radiusY + Math.cos(a) * Math.sin(rotationAngle) * radiusX;
			lineTo(cx + x1, cy + y1);
		}
		flush();
	}

	public function drawArc( cx : Float, cy : Float, radius : Float, angleStart:Float, angleLength:Float, segments = 0 ) {
		flush();
		if( Math.abs(angleLength) >= Math.PI * 2 + 1e-3 ) angleLength = Math.PI*2+1e-3;

		if( segments == 0 )
			segments = Math.ceil(Math.abs(radius * angleLength / 4));
		if( segments < 3 ) segments = 3;
		var angle = angleLength / (segments - 1);
		for( i in 0...segments ) {
			var a = i * angle + angleStart;
			lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
		}
		flush();
	}

	/**
		Draws a pie centered at given position.
		@param cx X center position of the pie.
		@param cy Y center position of the pie.
		@param radius Radius of the pie.
		@param angleStart Starting angle of the pie in radians.
		@param angleLength The pie size in clockwise direction with `2*PI` being full circle.
		@param segments Amount of segments used to draw the pie. When `0`, amount of segments calculated automatically.
	**/
	public function drawPie( cx : Int, cy : Int, radius : Int, angleStart:Float, angleLength:Float, segments = 0 ) {
		if(Math.abs(angleLength) >= Math.PI * 2) {
			return drawCircle(cx, cy, radius, segments);
		}
		flush();
		lineTo(cx, cy);
		if( segments == 0 )
			segments = Math.ceil(Math.abs(radius * angleLength / 4));
		if( segments < 3 ) segments = 3;
		var angle = angleLength / (segments - 1);
		for( i in 0...segments ) {
			var a = i * angle + angleStart;
			lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
		}
		lineTo(cx, cy);
		flush();
	}

	/**
		Draws a double-edged pie centered at given position.
		@param cx X center position of the pie.
		@param cy Y center position of the pie.
		@param radius The outer radius of the pie.
		@param innerRadius The inner radius of the pie.
		@param angleStart Starting angle of the pie in radians.
		@param angleLength The pie size in clockwise direction with `2*PI` being full circle.
		@param segments Amount of segments used to draw the pie. When `0`, amount of segments calculated automatically.
	**/
	public function drawPieInner( cx : Float, cy : Float, radius : Float, innerRadius : Float, angleStart:Float, angleLength:Float, segments = 0 ) {
		var cs = Math.cos(angleStart);
		var ss = Math.sin(angleStart);
		var ce = Math.cos(angleStart + angleLength);
		var se = Math.sin(angleStart + angleLength);

		lineTo(cx + cs * innerRadius, cy + ss * innerRadius);

		if( segments == 0 )
			segments = Math.ceil(Math.abs(radius * angleLength / 4));
		if( segments < 3 ) segments = 3;
		var angle = angleLength / (segments - 1);
		for( i in 0...segments ) {
			var a = i * angle + angleStart;
			lineTo(cx + Math.cos(a) * radius, cy + Math.sin(a) * radius);
		}
		lineTo(cx + ce * innerRadius, cy + se * innerRadius);
		for( i in 0...segments ) {
			var a = (segments - 1 - i) * angle + angleStart;
			lineTo(cx + Math.cos(a) * innerRadius, cy + Math.sin(a) * innerRadius);
		}
	}

	/**
		Draws a rectangular pie centered at given position.
		@param cx X center position of the pie.
		@param cy Y center position of the pie.
		@param width Width of the pie.
		@param height Height of the pie.
		@param angleStart Starting angle of the pie in radians.
		@param angleLength The pie size in clockwise direction with `2*PI` being solid rectangle.
		@param segments Amount of segments used to draw the pie. When `0`, amount of segments calculated automatically.
	**/
	public function drawRectanglePie( cx : Float, cy : Float, width : Float, height : Float, angleStart:Float, angleLength:Float, segments = 0 ) {
		if(Math.abs(angleLength) >= Math.PI*2) {
			return drawRect(cx-(width/2), cy-(height/2), width, height);
		}
		flush();
		lineTo(cx, cy);
		if( segments == 0 )
			segments = Math.ceil(Math.abs(Math.max(width, height) * angleLength / 4));
		if( segments < 3 ) segments = 3;
		var angle = angleLength / (segments - 1);
		var square2 = Math.sqrt(2);
		for( i in 0...segments ) {
			var a = i * angle + angleStart;

			var _width = Math.cos(a) * (width/2+1) * square2;
			var _height = Math.sin(a) * (height/2+1) * square2;

			_width = Math.abs(_width) >= width/2 ? (Math.cos(a) < 0 ? width/2*-1 : width/2) : _width;
			_height = Math.abs(_height) >= height/2 ? (Math.sin(a) < 0 ? height/2*-1 : height/2) : _height;

			lineTo(cx + _width, cy + _height);
		}
		lineTo(cx, cy);
		flush();
	}

	/**
	 * Draws a quadratic Bezier curve using the current line style from the current drawing position to (cx, cy) and using the control point that (bx, by) specifies.
	 * IvanK Lib port ( http://lib.ivank.net )
	 */
	public function curveTo( bx : Float, by : Float, cx : Float, cy : Float) {
		var ax = points.length == 0 ? 0 :points[ points.length - 1 ].x;
		var ay = points.length == 0 ? 0 :points[ points.length - 1 ].y;
		var t = 2 / 3;
		cubicCurveTo(ax + t * (bx - ax), ay + t * (by - ay), cx + t * (bx - cx), cy + t * (by - cy), cx, cy);
	}

	/**
	 * Draws a cubic Bezier curve from the current drawing position to the specified anchor point.
	 * IvanK Lib port ( http://lib.ivank.net )
	 * @param bx control X for start point
	 * @param by control Y for start point
	 * @param cx control X for end point
	 * @param cy control Y for end point
	 * @param dx end X
	 * @param dy end Y
	 * @param segments = 40
	 */
	public function cubicCurveTo( bx : Float, by : Float, cx : Float, cy : Float, dx : Float, dy : Float, segments = 40) {
		var ax = points.length == 0 ? 0 : points[points.length - 1].x;
		var ay = points.length == 0 ? 0 : points[points.length - 1].y;
		var tobx = bx - ax, toby = by - ay;
		var tocx = cx - bx, tocy = cy - by;
		var todx = dx - cx, tody = dy - cy;
		var step = 1 / segments;

		for (i in 1...segments) {
			var d = i * step;
			var px = ax + d * tobx, py = ay + d * toby;
			var qx = bx + d * tocx, qy = by + d * tocy;
			var rx = cx + d * todx, ry = cy + d * tody;
			var toqx = qx - px, toqy = qy - py;
			var torx = rx - qx, tory = ry - qy;

			var sx = px + d * toqx, sy = py + d * toqy;
			var tx = qx + d * torx, ty = qy + d * tory;
			var totx = tx - sx, toty = ty - sy;
			lineTo(sx + d * totx, sy + d * toty);
		}
		lineTo(dx, dy);
	}

	/**
		Draws a straight line from the current drawing position to the given position.
	**/
	public function lineTo( x : Float, y : Float ) {
		addVertex(x, y);
	}

	/**
		Adds new vertex to the current polygon with given parameters and current line style.
		@param x Vertex X position
		@param y Vertex Y position
	**/
	public function addVertex( x : Float, y : Float) {
		if( doFill ) {
			fillPoints++;
			add(x, y);
		}
		if (lineSize > 0) {
			points.push(new Point(x, y));
		}
	}
}
