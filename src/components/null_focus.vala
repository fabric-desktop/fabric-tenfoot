namespace Fabric.Tenfoot {
	/**
	 * Widget that can be focused, but is itself nothing.
	 *
	 * Use when making a modal that needs to take the focus away, but do
	 * nothing.
	 *
	 * Remember to remove from the widget tree when not needed.
	 */
	public class NullFocus : Gtk.Widget, ContextualWidget {
		construct {
			can_focus = true;
			focusable = true;
		}
	}
}
