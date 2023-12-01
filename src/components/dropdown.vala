namespace Fabric.Tenfoot {
	private string _dialog_value_string(uint selected, DropDown dropdown) {
		var model = dropdown.model;
		var expression = dropdown.expression;

		Value v = {};

		var item = model.get_object(selected);
		if (((GtkFIXED.Expression)expression).evaluate(item, ref v)) {
			return v.get_string();
		}
		else if (item.get_type().is_a(Type.STRING)) {
			return (string)item;
		}
		else {
			critical("Expression did not generate a string, or model is not a string.");
			return "[INVALID]";
		}
	}

	class DropDownDialogButton : MenuItem, ContextualWidget {
	}

	class DropDownDialog : Gtk.Box, ContextualWidget, ModalChild {
		private UI.ScrollingArea area;
		private List<weak DropDownDialogButton> buttons;

		public DropDown dropdown { get; private set; }

		public uint selected {
			get {
				var selected = dropdown.selected;
				if (dropdown.selected == Gtk.INVALID_LIST_POSITION) {
					selected = 0;
				}
				return selected;
			}
		}

		public DropDownDialog(DropDown dropdown) {
			Object(css_name: "tenfoot-dropdowndialog");
			this.dropdown = dropdown;
			update_values();
		}

		construct {
			add_css_class("tenfoot-dropdowndialog");

			buttons = new List<weak DropDownDialogButton>();

			orientation = Gtk.Orientation.VERTICAL;
			hexpand = true;
			halign = Gtk.Align.FILL;
			vexpand = true;
			valign = Gtk.Align.FILL;

			area = new UI.ScrollingArea() {
				hexpand = true,
				halign = Gtk.Align.FILL,
				vexpand = true,
				valign = Gtk.Align.FILL,
			};
			append(area);
			area.add_css_class("options");
			area.viewport_valign = Gtk.Align.CENTER;

			// Lock select action by default
			contextual_action_add("gamepad.primary", "Select").enabled = false;
			contextual_action_add("gamepad.back", "Cancel")
				.activate.connect(() => { this.close(); })
			;
		}

		protected void update_values() {
			// NOTE: This currently assumes this is ran exactly once.

			var model = dropdown.model;
			for (int i = 0; i < model.get_n_items(); i++) {
				var _button = new DropDownDialogButton();
				unowned var button = _button;
				var index = i;
				button.label = _dialog_value_string(i, dropdown);
				button.contextual_action_add("gamepad.primary", "Select")
					.activate.connect(() => { button.clicked(); })
				;
				button.clicked.connect(() => {
					dropdown.selected = index;
					this.close();
				});
				area.append(button);
				buttons.append(button);
			}
		}

		public override bool grab_focus() {
			return _handle_focus();
		}

		private bool _handle_focus() {
			if (buttons.nth_data(selected) != null) {
				var button = this.buttons.nth_data(this.selected);
				// For some awful reason, focusing in a ScrolledWindow seems
				// broken in some way...
				// ... or really, measuring and placing widgets happens way too
				// late.
				// Use implementation detail to determine if the rendering
				// has been done, and thus we scrolled.
				Graphene.Point point = {};
				button.compute_point(button.get_parent(), point, out point);
				// By checking and queueing the follow-up update *before* we
				// attempt to grab focus, we ensure it will be ran at least
				// once more after the check "succeeds", which still is
				// actually broken by the grab_focus animation.
				if (point.x == 0) {
					GLib.Timeout.add_once(50, () => {
#if 0
						debug("____ WORKAROUND FOR SCROLLING ____");
#endif
						_handle_focus();
					});
				}

				button.grab_focus();
				area.scroll_to_widget(button);

				return true;
			}
			return false;
		}

		public void on_close() {
			remove(area);
			area = null;
		}
	}

	public class DropDown : Gtk.Widget, ContextualWidget {
		public ListModel model { get; set; }
		public Gtk.Expression expression { get; set; }
		public uint selected { get; set; }

		private Gtk.Box layout;
		private Gtk.Label label;
		private Gtk.Button button;

		public DropDown(owned ListModel? model, owned Gtk.Expression? expression) {
			Object(css_name: "tenfoot-dropdown");
			this.model = model;
			this.expression = expression;
		}

		construct {
			set_layout_manager(new Gtk.BinLayout());
			selected = Gtk.INVALID_LIST_POSITION;

			can_focus = true;
			focusable = true;
			hexpand = true;
			halign = Gtk.Align.FILL;

			layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			layout.set_parent(this);

			label = new Gtk.Label("") {
				hexpand = true,
				xalign = 0,
			};
			label.add_css_class("dropdown-text");
			layout.append(label);

			button = new Gtk.Button() {
				halign = Gtk.Align.END,
				vexpand = true,
				valign = Gtk.Align.FILL,
				can_focus = false,
			};
			button.add_css_class("dropdown-button");
			layout.append(button);

			contextual_action_add("gamepad.primary", "Open").activate.connect(open);

			var click_handler = new Gtk.GestureClick();
			click_handler.propagation_phase = Gtk.PropagationPhase.CAPTURE;
			click_handler.touch_only = false;
			click_handler.button = Gdk.BUTTON_PRIMARY;
			click_handler.released.connect(open);
			add_controller(click_handler);

			notify["selected"].connect(update_value);
		}

		private void open() {
			var dialog = new DropDownDialog(this);
			dialog.show_modal();
		}

		public override void dispose() {
			layout.unparent();
		}

		private void update_value() {
			label.label = _dialog_value_string(selected, this);
		}
	}
}
