namespace Fabric.Tenfoot {
	class OSKButton : Gtk.Button {
		public OnScreenKeyboard keyboard { get { return layer.keyboard; } }
		public weak OSKLayer layer;
		public uint column {
			get; private set;
		}
		public uint width {
			get; private set;
		}

		public string key {
			get { return label; }
		}
		public OSKButton(OSKLayer layer, uint column, uint width, string key) {
			Object(css_name: "tenfoot-oskbutton");
			this.layer = layer;
			this.column = column;
			this.width = width;
			this.label = key;

			const string VALID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789";
			var classname = key.ascii_down();
			classname.canon(VALID_CHARS, '_');
			add_css_class("-key-%s".printf(classname));

			if (classname == "_empty_" || classname == "tab") {
				sensitive = false;
			}
		}
		construct {
			add_css_class("tenfoot-oskbutton");
			hexpand = true;
			halign = Gtk.Align.FILL;
			focusable = false;
			focus_on_click = false;

			clicked.connect(() => {
				this.keyboard.application.ensure_visible(this.keyboard.application.focus_widget);

				if (key.ascii_down() == "shift" || key.ascii_down() == "caps") {
					var sticky = key.ascii_down() == "caps";
					keyboard.change_layer(
						( layer.layer_name == OnScreenKeyboard.KeyboardLayerName.Primary )
						? OnScreenKeyboard.KeyboardLayerName.Secondary
						: OnScreenKeyboard.KeyboardLayerName.Primary
						, sticky
					);
					return;
				}

				if (key == "TAB") {
					// TODO: detect shifted layer?
					//keyboard.application.move_focus(Gtk.DirectionType.TAB_BACKWARD);
					keyboard.application.move_focus(Gtk.DirectionType.TAB_FORWARD);
					keyboard.handle_stickiness();
					return;
				}

				if (key == "Enter") {
					// we only support single-line fields for now...
					keyboard.application.move_focus(Gtk.DirectionType.TAB_FORWARD);
					keyboard.handle_stickiness();
					return;
				}

				var widget = keyboard.application.focus_widget;
				if (widget.get_type().is_a(typeof (Gtk.Editable))) {
					var editable = (Gtk.Editable)widget;
					var pos = editable.cursor_position;
					if (key == "backspace") {
						editable.do_delete_text(pos-1, pos);
					}
					else if (key == "left") {
						editable.set_position(pos-1);
					}
					else if (key == "right") {
						editable.set_position(pos+1);
					}
					else {
						editable.do_insert_text(key, -1, ref pos);
						editable.set_position(pos);
					}
				}

				keyboard.handle_stickiness();
			});
		}
	}
	class OSKRow : Gtk.Grid {
		public uint row { get; private set; }
		public List<OSKButton> buttons;

		public OSKRow(uint row) {
			this.row = row;
		}
		construct {
			this.buttons = new List<OSKButton>();
			hexpand = true;
			halign = Gtk.Align.FILL;
			column_homogeneous = true;
		}

		public void add_button(OSKButton button) {
			buttons.append(button);
			attach(button, (int)button.column, 1, (int)button.width);
		}

		public OSKButton get_button_for_column(uint col) {
			foreach (var button in buttons) {
				if (button.sensitive && col < (button.column + button.width)) {
					return button;
				}
			}
			return buttons.last().data;
		}
	}
	class OSKLayer : Gtk.Grid {
		public OnScreenKeyboard.KeyboardLayerName layer_name;
		public weak OnScreenKeyboard keyboard;
		public List<OSKRow> rows;

		public OSKLayer(OnScreenKeyboard keyboard, OnScreenKeyboard.KeyboardLayerName layer_name) {
			Object(css_name: "tenfoot-osk");
			add_css_class("tenfoot-osk");
			this.rows = new List<OSKRow>();
			this.layer_name = layer_name;
			this.keyboard = keyboard;
		}

		public void add_row(OSKRow osk_row) {
			rows.append(osk_row);
			attach(osk_row, 1, (int)osk_row.row);
		}

		construct {
			hexpand = true;
			halign = Gtk.Align.FILL;
			row_homogeneous = true;
		}
	}

	public class OnScreenKeyboard : Gtk.Widget, ContextualWidget {
		private static GLib.Once<OnScreenKeyboard> _instance;
		public static unowned OnScreenKeyboard instance {
			get { return _instance.once(() => { return new OnScreenKeyboard(); }); }
		}

		public enum KeyboardLayerName {
			Primary,   // None
			Secondary, // Shift/Caps
		}

		struct KeyboardKey {
			public string key;
		}

		struct KeyboardRow {
			public KeyboardKey[] keys;
		}

		struct KeyboardLayer {
			public KeyboardLayerName name;
			public KeyboardRow[] rows;

			KeyboardLayer(KeyboardLayerName name, KeyboardRow[] rows) {
				this.name = name;
				this.rows = rows;
			}
		}

		private static KeyboardLayer[] KEYBOARD_LAYERS;
		const int DEFAULT_WIDTH = 3;

		public Fabric.Tenfoot.Application application {
			get; set;
		}

		/**
		 * Width of keys that differ from the DEFAULT_WIDTH.
		 *
		 * This will be used as a colspan for the row-specific grid.
		 */
		private static HashTable<string, int> KEY_WIDTHS;

		private Gtk.Stack stack;
		private Gtk.Widget nothing;
		private Gtk.Stack keyboard_layers_stack;
		private HashTable<KeyboardLayerName, OSKLayer> layers;
		private KeyboardLayerName current_layer_name = Primary;
		// Used in case of non-sticky
		private KeyboardLayerName previous_layer_name = Primary;
		// When this is set to false, we switch layer after an event.
		private bool layer_is_sticky = true;
		// Indexed by List index.
		private int current_row_index;
		// Note: not by index in List, but by column in Grid-space.
		private int current_column_number;

		private OSKLayer current_layer {
			get {
				return layers[current_layer_name];
			}
		}
		private OSKRow current_row {
			get {
				return current_layer.rows.nth_data(current_row_index);
			}
		}

		private OSKButton current_button {
			owned get {
				return current_row.get_button_for_column(current_column_number);
			}
		}

		private OSKButton backspace_button;

		static construct {
			KEY_WIDTHS = new HashTable<string, int>(str_hash, str_equal);
			// Left-most column
			KEY_WIDTHS["TAB"] = 5;
			KEY_WIDTHS["CAPS"] = 6;
			KEY_WIDTHS["caps"] = 6;
			KEY_WIDTHS["SHIFT"] = 9;
			KEY_WIDTHS["shift"] = 9;
			KEY_WIDTHS["[empty]"] = 6;

			// Right-most column
			KEY_WIDTHS["backspace"] = 7;
			KEY_WIDTHS["\\"] = 5;
			KEY_WIDTHS["|"] = 5;
			KEY_WIDTHS["Enter"] = 7;
			// (shift already defined)

			// Other
			KEY_WIDTHS["left"] = 5;
			KEY_WIDTHS["right"] = 5;
			KEY_WIDTHS[" "] = 32;

		/**
		 * Naïve mapping to US QWERTY.
		 * TODO: add libxkbcommon support.
		 */
		KEYBOARD_LAYERS = {
			KeyboardLayer(Primary, {
				{{ {"`"}, {"1"}, {"2"}, {"3"}, {"4"}, {"5"}, {"6"}, {"7"}, {"8"}, {"9"}, {"0"}, {"-"}, {"="}, {"backspace"}, }},
				{{ {"TAB"}, {"q"}, {"w"}, {"e"}, {"r"}, {"t"}, {"y"}, {"u"}, {"i"}, {"o"}, {"p"}, {"["}, {"]"}, {"\\"}, }},
				{{ {"CAPS"}, {"a"}, {"s"}, {"d"}, {"f"}, {"g"}, {"h"}, {"j"}, {"k"}, {"l"}, {";"}, {"'"}, {"Enter"}, }},
				{{ {"SHIFT"}, {"z"}, {"x"}, {"c"}, {"v"}, {"b"}, {"n"}, {"m"}, {","}, {"."}, {"/"}, {"SHIFT"}, }},
				{{ {"[empty]"}, {" "}, {"left"}, {"right"},}},
			}),
			KeyboardLayer(Secondary, {
				{{ {"~"}, {"!"}, {"@"}, {"#"}, {"$"}, {"%"}, {"^"}, {"&"}, {"*"}, {"("}, {")"}, {"_"}, {"+"}, {"backspace"}, }},
				{{ {"TAB"}, {"Q"}, {"W"}, {"E"}, {"R"}, {"T"}, {"Y"}, {"U"}, {"I"}, {"O"}, {"P"}, {"{"}, {"}"}, {"|"}, }},
				{{ {"caps"}, {"A"}, {"S"}, {"D"}, {"F"}, {"G"}, {"H"}, {"J"}, {"K"}, {"L"}, {":"}, {"\""}, {"Enter"}, }},
				{{ {"shift"}, {"Z"}, {"X"}, {"C"}, {"V"}, {"B"}, {"N"}, {"M"}, {"<"}, {">"}, {"?"}, {"shift"}, }},
				{{ {"[empty]"}, {" "}, {"left"}, {"right"},}},
			}),
		};
		}

		private OnScreenKeyboard() {
			Object(css_name: "tenfoot-osk-container");
		}

		construct {
			set_layout_manager(new Gtk.BinLayout());
			layers = new HashTable<KeyboardLayerName, OSKLayer>(direct_hash, direct_equal);

			add_css_class("tenfoot-osk-container");
			valign = Gtk.Align.END;
			vexpand = false;

			stack = new Gtk.Stack() {
				vexpand = true,
				valign = Gtk.Align.FILL,
				hhomogeneous = true,
				vhomogeneous = false,
				transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN,
			};
			stack.set_parent(this);

			nothing = (Gtk.Widget)(new Gtk.Label(""));
			nothing.add_css_class("-nothing");
			stack.add_child(nothing);

			keyboard_layers_stack = new Gtk.Stack() {
				hhomogeneous = true,
				vhomogeneous = true,
				transition_type = Gtk.StackTransitionType.NONE,
			};
			stack.add_child(keyboard_layers_stack);

			foreach (var layer in KEYBOARD_LAYERS) {
				var osk_layer = new OSKLayer(this, layer.name);
				layers[layer.name] = osk_layer;
				keyboard_layers_stack.add_child(osk_layer);
				var row = 0;
				foreach (var keyboard_row in layer.rows) {
					var osk_row = new OSKRow(row);
					osk_layer.add_row(osk_row);
					row++;
					var column = 0;
					foreach (var key in keyboard_row.keys) {
						var width = DEFAULT_WIDTH;
						if (KEY_WIDTHS.contains(key.key)) {
							width = KEY_WIDTHS[key.key];
						}
						var button = new OSKButton(osk_layer, column, width, key.key);
						osk_row.add_button(button);
						column += width;
						if (key.key == "backspace") {
							backspace_button = button;
						}
					}
				}
			}

			{
				current_row_index = (int)(current_layer.rows.length()/2.0);
				var last_button = current_row.buttons.last().data;
				uint max = last_button.column + last_button.width;
				current_column_number = (int)(max/2.0);
				handle_fake_focus();
			}

			notify["application"].connect(() => {
				application.focus_widget_changed.connect(this.handle_focus_change);
			});

			contextual_action_add("gamepad.menu", "Menu").enabled = false;

			// TODO: map those actions to fake focus
			contextual_action_add("gamepad.up", "Up")
				.activate.connect(() => { move_fake_focus(-1, (int)current_button.width/2); })
			;
			contextual_action_add("gamepad.down", "Down")
				.activate.connect(() => { move_fake_focus(1, (int)current_button.width/2); })
			;
			contextual_action_add("gamepad.left", "Left")
				.activate.connect(() => { move_fake_focus(0, -1); })
			;
			contextual_action_add("gamepad.right", "Right")
				.activate.connect(() => { move_fake_focus(0, (int)current_button.width); })
			;
			contextual_action_add("gamepad.primary", "Select")
				.activate.connect(() => { current_button.clicked(); })
			;
			contextual_action_add("gamepad.secondary", "⌫")
				.activate.connect(() => { backspace_button.clicked(); })
			;

			contextual_action_add("gamepad.back", "Close")
				.activate.connect(() => { this.hide(); })
			;

			var touch_handler = new Gtk.GestureClick();
			touch_handler.propagation_phase = Gtk.PropagationPhase.CAPTURE;
			touch_handler.touch_only = true;
			touch_handler.released.connect(() => {
				remove_css_class("-with-gamepad");
			});
			add_controller(touch_handler);
		}

		public void change_layer(KeyboardLayerName layer_name, bool sticky) {
			layer_is_sticky = sticky;
			previous_layer_name = current_layer_name;
			current_layer_name = layer_name;
			keyboard_layers_stack.set_visible_child(layers[layer_name]);
			handle_fake_focus();
		}

		public void handle_stickiness() {
			if (!layer_is_sticky) {
				change_layer(previous_layer_name, true);
			}
		}

		public new void show(bool with_gamepad) {
			if (with_gamepad) {
				add_css_class("-with-gamepad");
			}
			else {
				remove_css_class("-with-gamepad");
			}
			application.override_contextual_focus(this);
			stack.set_visible_child(keyboard_layers_stack);
			var target = application.focus_widget;
			target.grab_focus();
			/* Sigh... */
			GLib.Timeout.add_once(50, () => {
				this.application.ensure_visible(this.application.focus_widget);
			});
		}

		public new void hide() {
			application.override_contextual_focus(null);
			stack.set_visible_child(nothing);
		}

		public void handle_focus_change() {
			var widget = application.focus_widget;
			if (widget != null && widget.get_type().is_a(typeof (Gtk.Editable))) {
				return;
			}

			hide();
		}

		/**
		 * Move the fake focus.
		 * Tip: +current_button.width in column_delta will go to the next button!
		 */
		private void move_fake_focus(int row_delta, int column_delta) {
			add_css_class("-with-gamepad");
			current_row_index += row_delta;
			current_column_number += column_delta;
			handle_fake_focus();
		}

		/**
		 * Refresh the current layer state according to the current fake focus
		 */
		private void handle_fake_focus() {
			// Clamp coordinates to rows
			if (current_row_index < 0) {
				current_row_index = 0;
			}
			if (current_row_index >= (int)current_layer.rows.length()-1) {
				current_row_index = (int)current_layer.rows.length()-1;
			}

			// Clamp coordinates to columns...
			if (current_column_number < 0) {
				current_column_number = 0;
			}
			var target_button = current_row.get_button_for_column(current_column_number);
			current_column_number = (int)target_button.column;

			foreach (var row in current_layer.rows) {
				foreach (var button in row.buttons) {
					button.remove_css_class("-is-focused");
				}
			}

			// Mark current target as focused
			current_button.add_css_class("-is-focused");
		}
	}
}
