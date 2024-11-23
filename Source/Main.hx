import lime.graphics.WebGLRenderContext;
import lime.graphics.opengl.GL;
import lime.math.Vector2;

import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.utils.Assets;
import openfl.display3D.Context3D;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.GraphicsShader;

import pixellate.draw.Command;
import pixellate.draw.Drawable;
import pixellate.draw.Shapes;
import pixellate.draw.Color;
import pixellate.draw.Mode;
import pixellate.draw.Color.rgba;
import pixellate.PixellateLayer;
import pixellate.PixelGraphics;

import slide.Slide;

class Main extends Sprite {

	private var g:PixelGraphics;
	private var layers:Array<PixellateLayer> = [];

	private var img2:Bitmap;

	public function new() {
		super();

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		addEventListener(MouseEvent.CLICK, onClick);

		stage.window.frameRate = 60;
		stage.color = 0xffffffff;

		// Add a Bitmap to demonstrate that Pixellate works with existing DisplayObjects
		var img1 = new Bitmap(Assets.getBitmapData("assets/3.png"));
		img1.x = 150;
		img1.y = 125;
		img1.scaleX = 2;
        img1.scaleY = 2;
		addChild(img1);

		// Create a Drawable by manually configured the points and commands
		var l = new Drawable();
		l.points = [
			0, 0,
			0, 1,
			0, 2,
			0, 3,
			0, 4,
			0, 5,
			1, 5,
			2, 5,
			3, 5,
		];
		l.commands.push(new Command(Mode.POINTS, Color.BLACK, 0, 9));

		// Create a Drawable by manually configured the points and commands
		var f = new Drawable();
		f.points = [
			// left column
			0, 0,
			30, 0,
			0, 150,
			0, 150,
			30, 0,
			30, 150,
			// top rung
			30, 0,
			100, 0,
			30, 30,
			30, 30,
			100, 0,
			100, 30,
			// middle rung
			30, 60,
			67, 60,
			30, 90,
			30, 90,
			67, 60,
			67, 90,
		];
		f.commands.push(new Command(Mode.TRIANGLES, Color.BLACK, 0, 18));

		// Add the PixelGraphics as a child of the current Sprite
		var bmpData = new BitmapData(450,350);
		this.g = new PixelGraphics(stage.context3D, cast GL.context, bmpData);
		g.x = 0;
		g.y = 0;
		g.scaleX = 2;
        g.scaleY = 2;
		addChild(this.g);

		// Add many instances of the custom F Drawable from above
		trace('PixelGraphics:');
		var ts1:Float = haxe.Timer.stamp();
		for (i in 0...15) {
			this.pixellateF(f);
		}
		var ts2:Float = haxe.Timer.stamp();
		trace('PixelGraphics: ${ts2 - ts1}');

		// Add the custom L Drawable which demonstrates using a different Mode
		var l = this.g.pixellate(l);
		l.translate.setTo(5,100);
		l.shear.setTo(-1, 0);

		// Add a Bitmap with an OpenFL Shader to demonstrate support for existing functionality
		this.img2 = new Bitmap(Assets.getBitmapData("assets/slice.png"));
		img2.x = 250;
		img2.y = 100;
		img2.scaleX = 2;
        img2.scaleY = 2;
		img2.shader = new RedShader(50);
		addChild(img2);

		// Create a circle and render using PixelGraphics instance
		var s1 = new Shapes();
		s1.circle(new Color({ fill:rgba(0.0, 1.0, 0.0, 1) }), 30, 30, 15);
		
		var pg = new PixelGraphics(stage.context3D, cast GL.context, new BitmapData(100,100));
		
		var circle = pg.pixellate(s1.drawable);
		circle.origin.setTo(30 * 1.5,30 * 1.5);
		circle.translate.setTo(15,15);
		circle.scale.setTo(1.5, 1.5);
		pg.x = 50;
		pg.y = 50;
		pg.scaleX = 2;
        pg.scaleY = 2;
		addChild(pg);

		// Simple example of animated Drawable(s) that are not originally positioned at 0,0
		addChild(this.circleSquareAnimation());

		// Demonstrates drawing Shapes similar to the pygame-ce examples
		addChild(this.pygameExamples(stage.context3D, cast GL.context));

		// Shows using PixelGraphics to rebuffer Drawable(s) dynamically
		// Unfortunately this particular approach is not particularly performant with large numbers of Drawable(s) because of the continual rebuffering
		addChild(this.rebufferAnimation(stage.context3D, cast GL.context));
		
		// Add 1000 Fs when clicking a button to test performance
		this.increaseFs(stage.context3D, cast GL.context, this, f);

		var fps_mem:FPS_Mem = new FPS_Mem(10, 10, 0x000000);
		addChild(fps_mem);
	}

	private function pixellateF(drawable:Drawable) {
		var f = this.g.pixellate(drawable);
		this.layers.push(f);
		f.drawable.commands[0].color = { r:Random.float(0,1), g:Random.float(0,1), b:Random.float(0,1), a:1.0 };
		f.origin.setTo(50 * 0.44, 75 * 0.76);
		f.translate.setTo(Random.int(100,400), Random.int(100,300));
		f.scale.setTo(0.44, 0.76);
	}

	private function increaseFs(ctx:Context3D, gl:WebGLRenderContext, sprite:Sprite, f:Drawable) {
		var shapes = new Shapes();
		shapes.rect(new Color({ stroke:rgba(0xff8f0101), fill:rgba(0xff999999) }), 5, 5, 75, 20, 2, 3);

		var pg = new PixelGraphics(ctx, gl, new BitmapData(85,30), 2);
		pg.x = 800;
		pg.y = 30;
		pg.pixellate(shapes.drawable, false);
		
		var button = new Sprite();
		button.addChild(pg);
		button.addEventListener(MouseEvent.CLICK, function(e) {
			for (i in 0...1000) {
				this.pixellateF(f);
			}
			trace("Added 1000 Fs, Total: " + this.layers.length);
		});

		sprite.addChild(button);

		var textfield = new TextField();
		textfield.x = 817;
		textfield.y = 42;
		textfield.scaleX = 2;
		textfield.scaleY = 2;
		textfield.text = "Add 1000 Fs";
		button.addChild(textfield);

		sprite.addChild(button);
	}

	private function rebufferAnimation(ctx:Context3D, gl:WebGLRenderContext) {
		var shapes = new Shapes();

		var pacmans:Array<Pacman> = [];
		for (i in 0...5) {
			var pacman = new Pacman(new Color({ fill:rgba(Random.int(0,255), Random.int(0,255), Random.int(0,255)) }),
				Random.int(50, 300), Random.int(25, 275), new Vector2(15, 315));
			pacmans.push(pacman);

			Slide.tween(pacman)
				.to({x:300}, 5.0)
				.ease(slide.easing.Quad.easeOut)
				.repeat()
				.start();
			Slide.tween(pacman.mouth)
				.to({y:345}, 0.5)
				.to({y:315}, 0.5)
				.repeat()
				.start();
		}

		var timer = new Timer();
		timer.start();

		var pg = new PixelGraphics(ctx, gl, new BitmapData(400,300), 2);
		pg.addEventListener(Event.ENTER_FRAME, function(e) {
			Slide.step(timer.tick().delta);

			pg.clear(true);
			shapes.clear();
			for (pacman in pacmans) {
				shapes.pie(pacman.color, pacman.x, pacman.y, 20, 0, pacman.mouth.x * Math.PI/180, pacman.mouth.y * Math.PI/180);
			}
			pg.pixellate(shapes.drawable, false);
		});

		return pg;
	}

	private function pygameExamples(ctx:Context3D, gl:WebGLRenderContext) {
		var pg = new PixelGraphics(ctx, gl, new BitmapData(400,300), 2);

		var shapes = new Shapes();
		shapes.rect(new Color({ fill:rgba(1.0, 1.0, 1.0, 0.7) }), 0, 0, 400, 300);

		pg.pixellate(shapes.drawable);

		shapes.clear();
		// shapes.circle(new Color({ fill:Color.BLACK }), 5 + 12, 105 + 12, 12);
		shapes.rect(new Color({ fill:rgba(1.0, 0.0, 0.0, 0.5) }), 0, 0, 30, 30);

		var rect1 = pg.pixellate(shapes.drawable);
		rect1.translate.setTo(25, 105);
		rect1.origin.setTo(30, 30);
		rect1.rotation = 0.0;
		rect1.scale.setTo(0.5, 0.5);
		rect1.shear.setTo(3.0, 3.0);

		var rect2 = pg.pixellate(shapes.drawable);
		rect2.translate.setTo(25, 105);
		rect2.shear.setTo(0.0, -1.0);
		rect2.rotation = 0.0;

		var rect3 = pg.pixellate(shapes.drawable);
		rect3.translate.setTo(25, 105);
		rect3.shear.setTo(0.0, 0.0);

		Slide.tween(rect3.shear)
				.to({x:1.0}, 1.0)
				.to({x:-1.0}, 2.0)
				.to({x:0}, 1.0)
				.to({y:1.0}, 1.0)
				.to({y:-1.0}, 2.0)
				.to({y:0}, 1.0)
				.ease(slide.easing.Quad.easeOut)
				.repeat()
				.start();

		pg.addEventListener(Event.ENTER_FRAME, function(e) {
			rect1.rotation += 0.5;
			rect2.rotation += 0.5;
		});

		shapes.clear();
		shapes.rect(new Color({ stroke:rgba(1.0, 0, 0, 0.5) }), 25, 105, 30, 30, 1);
		pg.pixellate(shapes.drawable);

		shapes.clear();
		shapes.line(Color.rgba(0xFB01B534), 0, 0, 50, 30, 5);
		shapes.line(rgba(0x9E03DF42), 0, 25, 50, 55, 3);
		shapes.line(rgba(0xFF05EA46), 0, 40, 50, 70);
		shapes.line(rgba(0xff05b8ea), 0, 50, 50, 80);

		pg.pixellate(shapes.drawable);
		// TODO??? lines1.color = { r:60/255, g:179/255, b:11/255, a:0.9 };

		shapes.clear();
		shapes.lines(Color.BLACK, [0, 80, 50, 90, 200, 80, 220, 30], 5);
		shapes.lines(Color.BLACK, [0, 87, 50, 97, 205, 87, 225, 37], 1);

		pg.pixellate(shapes.drawable);

		shapes.clear();
		shapes.rect(new Color({ stroke:rgba(0,0,0) }), 75, 10, 50, 20, 2);
		shapes.rect(new Color({ fill:rgba(0,0,0,0.7) }), 150, 10, 50, 20);
		shapes.rect(new Color({ fill:rgba(0,0,0,0.7) }), 170, 32, 40, 14);
		shapes.rect(new Color({ stroke:rgba(100,20,60), fill:rgba(0,0,0,0.4) }), 115, 40, 50, 20, 3);

		pg.pixellate(shapes.drawable);

		shapes.clear();
		shapes.line(Color.rgba(60,179,113), 115, 65, 115, 70, 1);
		shapes.line(Color.rgba(60,179,113), 165, 65, 165, 70, 1);

		shapes.rect(new Color({ fill:rgba(0,0,255,0.5) }), 195, 255, 70, 40, 0, 15);
		shapes.rect(new Color({ stroke:rgba(0,255,0,0.7) }), 115, 210, 70, 40, 14, 15);

		pg.pixellate(shapes.drawable);

		shapes.clear();
		shapes.rect(new Color({ stroke:rgba(255,0,0), fill:rgba(0,0,0,0.3) }), 0, 0, 70, 40, 1, 15);

		var rect = pg.pixellate(shapes.drawable);
		rect.translate.setTo(195, 210);

		Slide.tween(rect.scale)
				.to({x:2.0}, 1.0)
				.to({x:1.0}, 2.0)
				.to({y:2.0}, 1.0)
				.to({y:1.0}, 2.0)
				.ease(slide.easing.Quad.easeOut)
				.repeat()
				.start();

		shapes.clear();
		shapes.ellipse(new Color({ stroke:rgba(255,0,0), fill:rgba(0,0,255,0.3) }), 225, 25, 50/2, 20/2, 2);
    	shapes.ellipse(new Color({ fill:rgba(255,0,0,0.3) }), 300, 25, 50/2, 20/2);

		shapes.polygon(rgba(0x786C3C05), [5, 175, 35, 290, 105, 175, 5, 275], 4);

		shapes.circle(new Color({ stroke:rgba(0,0,255), fill:rgba(0,0,255,0.2) }), 60, 250, 40, 4);
		trace('shapes.circle:');
		var ts1:Float = haxe.Timer.stamp();
		var color = new Color({ stroke:rgba(0,0,255), fill:rgba(0,0,255,0.2) });
		for (i in 0...10) {
			shapes.circle(color, 60, 250, 20, 2);
		}
		var ts2:Float = haxe.Timer.stamp();
		trace('shapes.circle: ${ts2 - ts1}');

		shapes.pie(new Color({ fill:rgba(0xff8CAD07) }), 300, 75, 20, 0, 0 * Math.PI/180, 90 * Math.PI/180);
		shapes.pie(new Color({ stroke:rgba(0xffAD6007), fill:rgba(0xff8CAD07) }), 275, 75, 20, 0, 0 * Math.PI/180, -270 * Math.PI/180, 4);

		shapes.pie(new Color({ stroke:rgba(0xffAD6007) }), 325 ,75 ,20 ,10 ,0 * Math.PI/180, 90 * Math.PI/180, 1);
		shapes.arc(new Color({ stroke:rgba(0xffAD6007) }), 350, 75, 20, 0, -Math.PI/2, 1);

		shapes.lines(rgba(0,0,0), [150, 100, 175, 115, 140, 107], 1);

		shapes.beginFill(rgba(0xFFF7DB8D));
		shapes.lineStyle(5,rgba( 0x8707cdd4));
		shapes.moveTo(200,150);
		shapes.curveTo(300,160,300,238);
		shapes.lineTo(200,150);
		shapes.endFill();

		shapes.beginFill(rgba(0xFFFC86EA));
		shapes.lineStyle(2, rgba(0xffD40741));
		shapes.moveTo(15,15);
		shapes.cubicCurveTo(65,85,145,125,25,55);
		shapes.endFill();

		shapes.beginFill(rgba(0xFFFC86EA));
		shapes.lineStyle(2, rgba(0xffD40741));
		shapes.moveTo(255,15);
		shapes.cubicCurveTo(240,15,350,1,325,15);
		shapes.endFill();

		shapes.polygon(rgba(0,0,0), [100, 100, 10, 200, 200, 200], 5);

		pg.pixellate(shapes.drawable);

		return pg;
	}

	private function circleSquareAnimation():PixelGraphics {
		var s1 = new Shapes();
		s1.circle(new Color({}), 0, 0, 25);

		var s2 = new Shapes();
		s2.rect(new Color({}), 0, 0, 50, 50);

		var pg = new PixelGraphics(stage.context3D, cast GL.context, new BitmapData(100,100));
		// trace(s1.draw.shapes);
		var circle = pg.pixellate(s1.drawable);
		circle.drawable.commands[0].color = { r:0, g:0, b:1, a:1 };
		circle.origin.setTo(25,0);
		circle.translate.setTo(50,25);
		circle.rotation = 90;

		var square = pg.pixellate(s2.drawable);
		square.drawable.commands[0].color = { r:0, g:1, b:1, a:1 };
		square.origin.setTo(0,25);
		square.translate.setTo(50,25);
		square.rotation = 90;

		pg.x = 150;
		pg.y = 150;
		pg.scaleX = 2;
        pg.scaleY = 2;
		pg.addEventListener(Event.ENTER_FRAME, function(e) {
			// TODO??? Actuate
			if (circle.scale.x >= 1) {
				circle.scale.setTo(0,0);
				circle.rotation = 0;
				circle.drawable.commands[0].color.a = 1;

				square.scale.setTo(0,0);
				square.rotation = 0;
			  }
			var t = 0.01;
			circle.scale.x += t;
			circle.scale.y += t;
			circle.rotation += 10;
			circle.origin.setTo(25 * circle.scale.x,0);
			circle.drawable.commands[0].color.a -= 0.005;

			square.scale.x += t;
			square.scale.y += t;
			square.rotation += 10;
			square.origin.setTo(0,25 * square.scale.y);
		});

		return pg;
	}

	public function onEnterFrame(event:Event):Void {
		for (layer in this.layers) {
			layer.rotation += 0.1;
		}
	}

	public function onClick(event:MouseEvent):Void {
		this.img2.x = event.localX;
		this.img2.y = event.localY;
	}
}

class RedShader extends GraphicsShader {
	@:glFragmentSource("
		#pragma header
		uniform float uWidth;
		void main(void) {
			#pragma body
			float x = uWidth / 255.0;
			gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
			if (gl_FragColor.a != 0.0) {
				gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
			}
		}"
	)

	public function new(red:Float = 0) {
		super();
	
		data.uWidth.value = [red];
	}
}

class Timer {
	public var previous:Float = 0;
	public var current:Float = 0;
	public var delta:Float = 0;

	public function new() {}

	public function start() {
		this.current = haxe.Timer.stamp();
	}

	public function tick():Timer {
		this.previous = this.current;
		this.current = haxe.Timer.stamp();
		this.delta = this.current - this.previous;
		return this;
	}
}

class Pacman {
	public var color:Color;
	public var x:Float;
	public var y:Float;
	public var mouth:Vector2;

	public function new(color:Color, x:Float, y:Float, mouth:Vector2) {
		this.color = color;
		this.x = x;
		this.y = y;
		this.mouth = mouth;
	}
}

class FPS_Mem extends TextField {
	private var times:Array<Float>;
	private var memPeak:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000) {
		super();

		x = inX;
		y = inY;
		selectable = false;

		defaultTextFormat = new TextFormat("_sans", 12, inCol);
		text = "FPS: ";

		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 150;
		height = 70;
	}

	private function onEnter(_) {	
		var now = haxe.Timer.stamp();

		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100)/100;
		if (mem > memPeak) memPeak = mem;

		if (visible) {	
			text = "FPS: " + times.length + "\nMEM: " + mem + " MB\nMEM peak: " + memPeak + " MB";	
		}
	}
}
