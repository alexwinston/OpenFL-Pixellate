package pixellate.draw;

// https://people.eecs.ku.edu/~jrmiller/Courses/OpenGL/resources/PointAssociationModes.html
final class Mode {
	public static inline final POINTS = 0x0000;
	public static inline final LINE_STRIP = 0x0003;
	public static inline final TRIANGLES = 0x0004;
	public static inline final TRIANGLE_STRIP = 0x0005;
	public static inline final TRIANGLE_FAN = 0x0006;
}