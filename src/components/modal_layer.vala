namespace Fabric.Tenfoot {
	public interface ModalChild : Gtk.Widget {
		public new void show_modal() {
			var layer = ModalLayer.instance;
			layer.set_child(this);
			layer.show();
		}
		public void close() {
			var layer = ModalLayer.instance;
			if (layer.get_child() != this) {
				error("Attempted to unstack the wrong modal child.");
			}
			layer.hide();
		}
		public abstract void on_close();
	}

	/**
	 * The layer will, by default, be closeable with (B).
	 *
	 * Note that making the child a ContextualWidget, and overriding the
	 * action for something else is recommended.
	 */
	class ModalLayer : Gtk.Box, ContextualWidget {
		private static GLib.Once<ModalLayer> _instance;
		public static unowned ModalLayer instance {
			get { return _instance.once(() => { return new ModalLayer(); }); }
		}

		private ModalLayer() {}

		construct {
			add_css_class("modal-layer");

			hexpand = true;
			halign = Gtk.Align.FILL;
			vexpand = true;
			valign = Gtk.Align.FILL;

			var menu_action = contextual_action_add("gamepad.menu", "Menu");
			menu_action.activate.connect(() => {});
			menu_action.enabled = false;

			contextual_action_add("gamepad.back", "Close")
				.activate.connect(() => {
					get_child().close();
				})
			;

			_hide();
		}

		public unowned ModalChild get_child() {
			return (ModalChild)get_first_child();
		}

		public void set_child(ModalChild child) {
			remove_all_child();
			append(child);
		}

		private void _hide() {
			set_sensitive(false);
			remove_css_class("-is-shown");
			// Ensure the CSS-based animation has ran.
			GLib.Timeout.add_once((uint)(0.15 * 1000), () => {
				// Prevents a modal shown after a modal to accidentally be closed.
				if (!this.sensitive) {
					get_child().on_close();
					set_visible(false);
					remove_all_child();
				}
			});
		}

		public new void hide() {
			var application = (Application)GLib.Application.get_default();
			application.page_focus_target_pop(this);
			_hide();
		}

		public new void show() {
			var application = (Application)GLib.Application.get_default();
			application.page_focus_target_push(this);
			set_sensitive(true);
			set_visible(true);
			GLib.Idle.add_once(() => {
				add_css_class("-is-shown");
			});
		}

		public void remove_all_child() {
			while (get_first_child() != null) {
				remove(get_first_child());
			}
		}
	}
}
