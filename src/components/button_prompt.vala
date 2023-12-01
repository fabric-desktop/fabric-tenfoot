namespace Fabric.Tenfoot {
	/**
	 * Cosmetic button representing a gamepad button and logical label.
	 */
	public class ButtonPrompt : Gtk.Button {
		protected Gtk.Box container;
		protected Gtk.Box button_widget_bg;
		protected Gtk.Label button_widget;
		protected Gtk.Label name_label;

		public ButtonPrompt(string name, string button) {
			name_label.label = name;
			button_widget.label = button;
			add_css_class("-button-%s".printf(button.ascii_down()));
		}

		public new string label {
			get { return name_label.label; }
			set { name_label.label = value; }
		}

		public new string symbol {
			get { return button_widget.label; }
			set { button_widget.label = value; }
		}

		construct {
			container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				hexpand = true,
				halign = Gtk.Align.FILL,
				valign = Gtk.Align.CENTER,
			};
			child = container;

			add_css_class("button-prompt");
			add_css_class("-is-button");
			hexpand = true;
			valign = Gtk.Align.CENTER;
			halign = Gtk.Align.FILL;
			name_label = new Gtk.Label("<...>");
			name_label.add_css_class("name");
			button_widget = new Gtk.Label("") {
				hexpand = true,
				halign = Gtk.Align.FILL,
			};

			button_widget.add_css_class("buttonlabel");
			button_widget_bg = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				hexpand = true,
				halign = Gtk.Align.FILL,
			};
			button_widget_bg.add_css_class("button");

			button_widget_bg.append(button_widget);
			container.append(button_widget_bg);
			container.append(name_label);

			// They are only buttons for touch/click input.
			// Their actions are keyboard-able via global events (gamepad, keyboard).
			can_focus = false;
		}
	}
}
