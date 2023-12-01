namespace Fabric.Tenfoot {
	/**
	 * This is a "menu item-shaped" button.
	 *
	 * The intended use is within a list of actions, and fills the width.
	 *
	 * E.g. full-width and meant for a vertical menu.
	 */
	public class MenuItem : Gtk.Button {
		construct {
			add_css_class("tenfoot-menu-item");
			hexpand = true;
			// Set a label to force the implicit label child to exist.
			label = "[...]";
			child.hexpand = false;
			child.halign = Gtk.Align.START;
		}
	}
}
