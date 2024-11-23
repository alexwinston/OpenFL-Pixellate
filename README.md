# OpenFL-Pixellate

A graphics pixelation library for OpenFL that renders meshes to pixel perfect Bitmap textures using OpenGL.

The Pixellate library supports and has been tested on all the OpenGL render contexts available in OpenFL. This includes every supported platform except Flash and Air.

Performance is very good although additional optimizations and pooling could be added to increase FPS.  Simple benchmarking tests show that buffered meshes can render between 10k and 30k layers at 60 FPS. For dynamically rendered and buffered meshes performance is however only in the 2k-3k range. The library is designed around the idea of reusable Drawable(s) that are subsequently transformed per frame as desired.

Pixellate was heavily inspired by Love2d and Heaps.

Features:
* Simple Drawable class definition representing mesh points and colors defined by a set of Command(s) that render to a Bitmap texture
* Shapes class that provides an assortment of Drawable primitives ready to be pixellated
* PixelGraphics class that wraps a Bitmap texture and composites the Drawable commands using a custom OpenGL Shader
* PixellateLayer class that exposes transformation properties per Drawable instance

![Pixellate](https://raw.githubusercontent.com/alexwinston/OpenFL-Pixellate/refs/heads/main/example.png 'Pixellate')

## Demo
The demo provides a myriad of examples for using multiple PixelGraphics to display and animate layers created with Drawable(s) by hand as well as using the Shapes class. Existing OpenFL Shader support is demonstrated to work as well alongside Pixellate.
```shell
lime test hl
```

## Drawable
A Drawable is the most foundational class of the Pixellate library.  It represents a set of points and colors to be rendered using the desired OpenGL drawing mode for each Command.

The following example demonstrates how to instantiate a new Drawable and configure points that represent a triangle. A combination of commands representing a sequence of points each with the desired start and stop index is supported for more complex drawing.
```haxe
var drawable = new Drawable();
drawable.points = [
    10, 0,
    20, 20,
    0, 20
]
drawable.commands.push(new Command(Mode.TRIANGLES, Color.BLACK, 0, 3));
```

## PixelGraphics
The PixelGraphics class is responsible for taking Drawable(s) and rendering them to the underlying Bitmap texture.

Instantiating a PixelGraphics requires a BitmapData of the desired size. Because the PixelGraphics extends Bitmap it can be positioned, transformed and scaled as desired. It then can be added to a DisplayObject as typical in OpenFL. Drawable(s) are added to the PixelGraphics instance using the pixellate method that buffers and caches the Drawable and subsequently returns a PixellateLayer that can be transformed as needed. The layer is positioned relative to the Bitmap underlying the PixelGraphics.

```haxe
var bmpData = new BitmapData(300,300);
var pixelGraphics = new PixelGraphics(stage.context3D, cast GL.context, bmpData);
pixelGraphics.x = 0;
pixelGraphics.y = 0;
pixelGraphics.scaleX = 2;
pixelGraphics.scaleY = 2;
addChild(this.g);

var triangleLayer = pixelGraphics.pixellate(drawable);
triangleLayer.translate.setTo(100, 100);
triangleLayer.origin.setTo(10, 10);
triangleLayer.rotation = 90;
```

## Shapes
The Shapes class provides a set of methods that create Drawable meshes for most common shapes.  The Shapes class is additve and appends drawing commands to the current underlying Drawable instance.

```haxe
var shapes = new Shapes();
shapes.rect(new Color({ stroke:rgba(100,20,60), fill:rgba(0,0,0,0.4) }), 115, 40, 50, 20, 3);

var rectLayer = pg.pixellate(shapes.drawable);
// Transform layer as desired

shapes.clear();
shapes.rect(new Color({ stroke:rgba(100,20,60), fill:rgba(0,0,0,0.4) }), 0, 0, 50, 20, 3);

// This layer is seperate from the previous pixellated Drawable instance because clear was called to reset the Shapes class. A seperate buffer is created per Drawable by the PixelGraphics class.
var rectLayer2 = pg.pixellate(shapes.drawable);

```

It should be noted that because Drawable(s) meshes are similar to typical 3d object meshes care should be taken regarding the intial position the points are configured at.  It is suggested that using 0,0 as the underlying Drawable upper left position in order to more easily transform PixellateLayer(s). However if the desired mesh points are not likely to change configuring the points to the desired position directly is supported.

```haxe
// Here the rectangle points are set from the starting position of 100,100.  Subsequent PixellateLayer transforms will need to account for the original position.
shapes.rect(new Color({ stroke:rgba(100,20,60), fill:rgba(0,0,0,0.4) }), 100, 100, 50, 20, 3);
```

## TODO
Currently Pixellate provides a fair amount of functionality but the following features would be nice to add in the future
* Publish Pixellate to haxelib
* More expansive support for interesting mesh Shapes
* Texture fill support to allow for gradients or custom fills instead of just solid colors
* Fix alpha support across all PixellateLayer(s). This requires sorting support for transparent and non-tranparent layers I believe.
