namespace Fabric.Tenfoot {
	public class BottomBar : Gtk.Box {
		private static GLib.Once<BottomBar> _instance;
		public static unowned BottomBar instance {
			get { return _instance.once(() => { return new BottomBar(); }); }
		}

		private string type_as_class = "";
		private BottomBar() {}

		protected Gtk.Box left;
		protected Gtk.Box right;

		/**
		 * Table of all button prompts.
		 *
		 * Only the *menu* prompt is shown on the left.
		 *
		 * Indexed by (lowercased) button name.
		 */
		public HashTable<string, ButtonPrompt> buttons;

		construct {
			buttons = new HashTable<string, ButtonPrompt>(str_hash, str_equal);

			add_css_class("bottom-bar");
			orientation = Gtk.Orientation.HORIZONTAL;
			hexpand = true;
			halign = Gtk.Align.FILL;

			left = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				hexpand = true,
				halign = Gtk.Align.START,
			};
			left.add_css_class("left");
			append(left);

			right = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				hexpand = true,
				halign = Gtk.Align.END,
			};
			right.add_css_class("right");
			append(right);

			// To the left
			_add_button("menu",     "menu",     left, false);
			_add_button("options",  "options",  left);
			_add_button("overview", "overview", left);

			// To the right
			_add_button("tertiary",  "tertiary",  right);
			_add_button("secondary", "secondary", right);
			_add_button("back",      "back",      right, false);
			_add_button("primary",   "primary",   right, false);

			var gamepad = GamepadController.instance;
			gamepad.notify["gamepad-type"].connect(update_gamepad_type);
			update_gamepad_type();
		}

		/**
		 * Internal helper for making a button.
		 *
		 * When `hide` is false, the button will be kept on-screen even if the action is disabled.
		 */
		private void _add_button(string symbol, string button_name, Gtk.Box side, bool hide = true) {
			Application application = (Application)GLib.Application.get_default();
			string action_name = "gamepad.%s".printf(button_name);

			var label = "(unknown)";
			var button = new ButtonPrompt(label, symbol);
			buttons.insert(button_name, button);
			side.append(button);

			button.clicked.connect(() => {
				application.activate_contextual_action(action_name);
			});

			application.focus_widget_changed.connect(() => {
				var action = application.get_contextual_action(action_name);
				var enabled = action != null && action.enabled;
				button.visible = !hide || enabled;
				button.sensitive = enabled;
				if (action != null) {
					button.label = action.label;
				}
			});
		}

		private void update_gamepad_type() {
			if (type_as_class != "") {
				remove_css_class(type_as_class);
			}
			var gamepad_type = GamepadController.instance.gamepad_type;
			type_as_class = "-type-%s".printf(gamepad_type.to_string());
			add_css_class(type_as_class);

			switch (gamepad_type) {
				case GamepadController.GamepadType.KEYBOARD:
					buttons.lookup("menu").symbol      = "backspace";
					buttons.lookup("options").symbol   = "F3";
					buttons.lookup("overview").symbol  = "F4";

					buttons.lookup("tertiary").symbol  = "F2";
					buttons.lookup("secondary").symbol = "F1";
					buttons.lookup("back").symbol      = "Escape";
					buttons.lookup("primary").symbol   = "Return";
					break;
				case GamepadController.GamepadType.STEAM:
					buttons.lookup("menu").symbol      = "menu";
					buttons.lookup("options").symbol   = "start";
					buttons.lookup("overview").symbol  = "select";

					buttons.lookup("tertiary").symbol  = "Y";
					buttons.lookup("secondary").symbol = "X";
					buttons.lookup("back").symbol      = "B";
					buttons.lookup("primary").symbol   = "A";
					break;
				case GamepadController.GamepadType.NINTENDO:
					buttons.lookup("menu").symbol      = "home";
					buttons.lookup("options").symbol   = "start";
					buttons.lookup("overview").symbol  = "select";

					buttons.lookup("tertiary").symbol  = "Y";
					buttons.lookup("secondary").symbol = "X";
					buttons.lookup("back").symbol      = "B";
					buttons.lookup("primary").symbol   = "A";
					break;
				case GamepadController.GamepadType.PLAYSTATION:
					buttons.lookup("menu").symbol      = "menu";
					buttons.lookup("options").symbol   = "start";
					buttons.lookup("overview").symbol  = "select";

					buttons.lookup("tertiary").symbol  = "triangle";
					/*
					buttons.lookup("secondary").symbol = "circle";
					buttons.lookup("back").symbol      = "square";
					buttons.lookup("primary").symbol   = "x";
					*/
					buttons.lookup("secondary").symbol = "square";
					buttons.lookup("back").symbol      = "circle";
					buttons.lookup("primary").symbol   = "x";
					break;
				case GamepadController.GamepadType.XBOX:
					buttons.lookup("menu").symbol      = "menu";
					buttons.lookup("options").symbol   = "start";
					buttons.lookup("overview").symbol  = "back";

					buttons.lookup("tertiary").symbol  = "Y";
					buttons.lookup("secondary").symbol = "X";
					buttons.lookup("back").symbol      = "B";
					buttons.lookup("primary").symbol   = "A";
					break;
				default:
					buttons.lookup("menu").symbol      = "menu";
					buttons.lookup("options").symbol   = "options";
					buttons.lookup("overview").symbol  = "overview";

					buttons.lookup("tertiary").symbol  = "tertiary";
					buttons.lookup("secondary").symbol = "secondary";
					buttons.lookup("back").symbol      = "back";
					buttons.lookup("primary").symbol   = "primary";
					break;
			}
		}
	}
}
