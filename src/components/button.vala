namespace Fabric.Tenfoot {
	/**
	 * This is a "button-shaped" button.
	 *
	 * The intended use is within a page as a discrete control.
	 *
	 * E.g. pill-shaped, and prefers not being expanded.
	 */
	public class Button : Gtk.Button, ContextualWidget {
		construct {
			add_css_class("tenfoot-button");
			hexpand = false;
		}
	}
}
