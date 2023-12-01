namespace Fabric.Tenfoot {
	public class DialogButton : Gtk.Button, ContextualWidget {
		construct {
			add_css_class("dialog-button");
			hexpand = false;
		}
	}

	/**
	 * Represents a modal dialog, with optional buttons.
	 *
	 * Having no buttons defined will lock the user to the dialog, as no
	 * actions will be available, even the default cancel signal will not
	 * be usable.
	 *
	 * This can be used to show a modal dialog during a "global" event that
	 * takes time. For example, while connecting to the network.
	 *
	 * Though, when possible, never do this.
	 *
	 * Even more so: prefer not using a Dialog.
	 */
	public class Dialog : Gtk.Box, ContextualWidget, ModalChild {
		private Gtk.Label title_widget;
		private Gtk.Box body_widget;
		private Gtk.Box buttons_bar;
		private weak Gtk.Widget default_button;
		private NullFocus null_focus;

		/**
		 * Signal tied to the global cancel button.
		 *
		 * By default it does nothing. You likely want to connect to it and
		 * `close()` the dialog.
		 */
		public signal void cancel();

		construct {
			orientation = Gtk.Orientation.VERTICAL;
			hexpand = true;
			halign = Gtk.Align.CENTER;
			vexpand = false;
			valign = Gtk.Align.CENTER;
			
			add_css_class("dialog-box");

			title_widget = new Gtk.Label("") {
				halign = Gtk.Align.FILL,
				hexpand = true,
				xalign = 0,
			};
			title_widget.add_css_class("title");
			title_widget.visible = false;

			base.append(title_widget);

			body_widget = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
				halign = Gtk.Align.START,
			};
			body_widget.add_css_class("body");
			base.append(body_widget);

			buttons_bar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
					halign = Gtk.Align.END,
			};
			buttons_bar.add_css_class("buttons");
			base.append(buttons_bar);

			null_focus = new NullFocus();
			null_focus.contextual_action_add("gamepad.back", "Cancel").enabled = false;
			null_focus.contextual_action_add("gamepad.primary", "Select").enabled = false;
			buttons_bar.append(null_focus);
			default_button = null_focus;

			contextual_action_add("gamepad.back", "Cancel")
				.activate.connect(() => {
					this.cancel();
				})
			;
		}

		public new void append(Gtk.Widget widget) {
			body_widget.append(widget);
		}

		public new void remove(Gtk.Widget widget) {
			body_widget.remove(widget);
		}

		public DialogButton add_button(string label, bool make_default = false) {
			var button = new DialogButton();
			button.label = label;
			if (null_focus.visible) {
				buttons_bar.remove(null_focus);
				null_focus.visible = false;
			}
			buttons_bar.append(button);
			if (make_default) {
				default_button = button;
			}

			return button;
		}

		/**
		 * Use to add a cancel button, automatically tied to the cancel signal.
		 */
		public DialogButton add_cancel_button(bool make_default = false) {
			var button = add_button("Cancel", make_default);
			button.clicked.connect(() => {
				cancel();
			});
			return button;
		}

		/**
		 * Use to add an Ok button. Nothing tied to it by default.
		 */
		public DialogButton add_ok_button(bool make_default = false) {
			var button = add_button("Ok", make_default);
			return button;
		}

		public override bool grab_focus() {
			if (default_button == null_focus && !null_focus.visible) {
				error("Showing a dialog with buttons, but no default button set.");
			}
			return default_button.grab_focus();
		}

		public void set_title(string title) {
			title_widget.visible = true;
			title_widget.set_text(title);
		}

		public void on_close() {
			buttons_bar.unparent();
			buttons_bar = null;
		}
	}
}
