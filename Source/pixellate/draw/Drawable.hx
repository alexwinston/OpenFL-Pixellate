package pixellate.draw;

/**
	A simple interface to draw arbitrary 2D geometry.

	Usage notes:
	* While Graphics allows for multiple unique textures, each texture swap causes a new drawcall,
	and due to that it's recommended to minimize the amount of used textures per Graphics instance,
	ideally limiting to only one texture.
	* Due to how Graphics operate, removing them from the active `h2d.Scene` will cause a loss of all data.
**/
class Drawable {
	public var id:Int;
	public var index:Int;
	public var points:Array<Float>;
	public var commands:Array<Command>;

	public function new(id:Int = 0, index:Int = 0, ?shapes:Array<Float>, ?commands:Array<Command>) {
		this.id = id;
		this.index = index;
		this.points = points ?? [];
		this.commands = commands ?? [];
	}

	public function copy() {
		return new Drawable(this.id, this.index, this.points.map(s -> s), this.commands.map(c -> c.copy()));
	}
}