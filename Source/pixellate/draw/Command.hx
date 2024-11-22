package pixellate.draw;

import pixellate.draw.Color;

class Command {
	public var mode:Int;
	public var color:RGBA;
	public var i0:Int;
	public var i1:Int;

	public function new(mode, color, i0, i1) {
		this.mode = mode;
		this.color = color;
		this.i0 = i0;
		this.i1 = i1;
	}

	public function copy() {
		return new Command(this.mode, this.color, this.i0, this.i1);
	}
}