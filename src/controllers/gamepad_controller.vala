namespace Fabric.Tenfoot {
	class GamepadController : Object {
		private static GLib.Once<GamepadController> _instance;
		public static unowned GamepadController instance {
			get { return _instance.once(() => { return new GamepadController(); }); }
		}

		[Flags]
		public enum Direction {
			UP,
			DOWN,
			LEFT,
			RIGHT,
		}

		/**
		 * Axes, ordered in directional pairs.
		 */
		[Flags]
		public enum Axes {
			LEFT,
			RIGHT,
			UP,
			DOWN,
		}

		public enum GamepadType {
			UNKNOWN,
			KEYBOARD,
			STEAM,
			NINTENDO,
			PLAYSTATION,
			XBOX,
			_NONE;

			public string to_string() {
				switch (this) {
					case UNKNOWN:     return "unknown";
					case KEYBOARD:    return "keyboard";
					case STEAM:       return "steam";
					case NINTENDO:    return "nintendo";
					case PLAYSTATION: return "playstation";
					case XBOX:        return "xbox";
					default:          return "none";
				}
			}
		}

		const string VALID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789";

		/**
		 * Axis value must be this high to activate the (digital) action.
		 */
		const double ACTIVATION_ZONE = 0.7;

		// Keep a reference to ourselves to prevent being collected
		private static GamepadController self;
		private Manette.Monitor manette_monitor;
		private Manette.Device last_device;
		private uint current_direction = 0;
		// Pairs of bits representing the axes
		private uint axes_status = 0;

		public Fabric.Tenfoot.Application application {
			get; set;
		}
		public GamepadType gamepad_type {
			get; private set;
		}

		public string simplify_name(string name) {
			var tmp = name.ascii_down();
			tmp.canon(VALID_CHARS, '-');
			tmp = tmp
				.replace("xbox", "x-box")
				.replace("x-box360", "x-box-360")
				.replace("x-boxone", "x-box-one")
				.replace("playstation1", "playstation-1")
				.replace("playstation2", "playstation-2")
				.replace("playstation3", "playstation-3")
				.replace("playstation4", "playstation-4")
				.replace("playstation5", "playstation-5")
			;

			return tmp;
		}

		public GamepadType gamepad_type_for(Manette.Device? device) {
			if (device == null) {
				return GamepadType.KEYBOARD;
			}
			var simplified_name = simplify_name(device.get_name());

			if (simplified_name.index_of("steam") != -1) {
				return GamepadType.STEAM;
			}
			if (simplified_name.index_of("nintendo") != -1) {
				return GamepadType.NINTENDO;
			}
			if (simplified_name.index_of("playstation") != -1) {
				return GamepadType.PLAYSTATION;
			}
			if (simplified_name.index_of("twin-usb-joystick") != -1) {
				return GamepadType.PLAYSTATION;
			}
			if (simplified_name.index_of("x-box") != -1) {
				return GamepadType.XBOX;
			}

			return GamepadType.UNKNOWN;
		}

		private GamepadController() {
			self = this;
			gamepad_type = GamepadType.UNKNOWN;

			manette_monitor = new Manette.Monitor();
			manette_monitor.device_connected.connect(on_gamepad_connect);
			var iterator = manette_monitor.iterate();
			Manette.Device device;
			while (iterator.next(out device)) {
				on_gamepad_connect(device);
			}
		}

		private void on_gamepad_connect(Manette.Device device) {
			debug("GamepadController#on_gamepad_connect");
			debug("  New gamepad: %s", device.get_name());
			var simplified_name = simplify_name(device.get_name());
			debug("  Simplified name: %s", simplified_name);

			if (gamepad_type == GamepadType.UNKNOWN) {
				gamepad_type = gamepad_type_for(device);
			}

			// Send a quick shake on setup
			device.rumble(32767, 32767, 200);

			device.button_press_event.connect(on_button_press);
			device.button_release_event.connect(on_button_press);
			device.absolute_axis_event.connect(on_axis);
		}

		public void check_gamepad_change(Manette.Device? current_device) {
			if (last_device != current_device || (current_device == null && gamepad_type != GamepadType.KEYBOARD)) {
				gamepad_type = gamepad_type_for(current_device);
				var name = "Keyboard";
				if (current_device != null) {
					name = current_device.get_name();
				}
				debug(" -> Changing device for: %s (%u)", name, gamepad_type);
				last_device = current_device;
			}
		}

		/**
		 * Maps axis event to the handler function
		 */
		private void on_axis(Manette.Event event) {
			uint16 axis;
			double value;
			if (event.get_absolute(out axis, out value)) {
				handle_axis(axis, value, event.get_device());
			}
		}

		/**
		 * Translate the axis event to dpad event (1/2)
		 */
		private void handle_axis(uint16 axis, double value, Manette.Device device) {
			if (axis > 1) { return; }

			// The Axis direction we're actually interested in.
			uint16 index = axis*2;
			// The other side of that same axis
			uint16 other_index = axis*2;

			if (value > 0) { index += 1; }
			else { other_index += 1; }

			// Convert to position in bit field
			index = 1 << index;
			other_index = 1 << other_index;

			// When this large, make it a dpad press.
			if (value.abs() > ACTIVATION_ZONE) {
				if ((axes_status & index) == 0) {
					check_gamepad_change(device);
					// Ensures the other side of the axis is not held
					handle_axis_to_dpad(other_index, false);
					axes_status &= ~other_index;

					// Mark button as pressed, and execute dpad press
					axes_status |= index;
					handle_axis_to_dpad(index, true);
				}
			}
			else {
				// When smaller than ACTIVATION_ZONE, neither axes should be held
				if ((axes_status & index) != 0) {
					check_gamepad_change(device);
					axes_status &= ~index;
					handle_axis_to_dpad(index, false);
				}
				if ((axes_status & other_index) != 0) {
					check_gamepad_change(device);
					axes_status &= ~other_index;
					handle_axis_to_dpad(other_index, false);
				}
			}
		}

		/**
		 * Translate the axis event to dpad event (2/2)
		 */
		private void handle_axis_to_dpad(Axes axis, bool pressed) {
			switch (axis) {
				case Axes.UP:
					handle_direction(Direction.UP, pressed ? Manette.EventType.EVENT_BUTTON_PRESS : Manette.EventType.EVENT_BUTTON_RELEASE);
					break;
				case Axes.DOWN:
					handle_direction(Direction.DOWN, pressed ? Manette.EventType.EVENT_BUTTON_PRESS : Manette.EventType.EVENT_BUTTON_RELEASE);
					break;
				case Axes.RIGHT:
					handle_direction(Direction.RIGHT, pressed ? Manette.EventType.EVENT_BUTTON_PRESS : Manette.EventType.EVENT_BUTTON_RELEASE);
					break;
				case Axes.LEFT:
					handle_direction(Direction.LEFT, pressed ? Manette.EventType.EVENT_BUTTON_PRESS : Manette.EventType.EVENT_BUTTON_RELEASE);
					break;
			}
		}

		private void on_button_press(Manette.Event event) {
			check_gamepad_change(event.get_device());
			uint16 button;
			if (event.get_button(out button)) {
				handle_button(button, event.get_event_type());
			}
		}

		private bool handle_button_actions(string button_action, string logical_action) {
			if (application.activate_contextual_action(button_action)) {
				return true;
			}
			return application.activate_contextual_action(logical_action);
		}

		private void generate_one_direction_event(Direction direction) {
			switch (direction) {
				case Direction.UP:
					handle_button_actions("btn.up", "gamepad.up");
					break;
				case Direction.DOWN:
					handle_button_actions("btn.down", "gamepad.down");
					break;
				case Direction.LEFT:
					handle_button_actions("btn.left", "gamepad.left");
					break;
				case Direction.RIGHT:
					handle_button_actions("btn.right", "gamepad.right");
					break;
				default:
					break;
			}
		}

		private void add_dpad_timeout(Direction direction) {
			Timeout.add(300, () => {
				if ((current_direction & direction) == 0) { return false; }
				Timeout.add(50, () => {
					if ((current_direction & direction) == 0) { return false; }
					generate_one_direction_event(direction);
					return true;
				});
				return false;
			});
		}

		private void handle_direction(Direction direction, Manette.EventType type) {
			if (type == Manette.EventType.EVENT_BUTTON_PRESS) {
				current_direction |= direction;
				generate_one_direction_event(direction);
				add_dpad_timeout(direction);
			}
			else {
				current_direction &= ~direction;
			}
		}

		private void handle_button(uint16 button, Manette.EventType type) {
			// Handle repeating buttons.
			switch (button) {
				case EventCode.BTN_DPAD_UP:
					handle_direction(Direction.UP, type);
					return;
				case EventCode.BTN_DPAD_DOWN:
					handle_direction(Direction.DOWN, type);
					return;
				case EventCode.BTN_DPAD_LEFT:
					handle_direction(Direction.LEFT, type);
					return;
				case EventCode.BTN_DPAD_RIGHT:
					handle_direction(Direction.RIGHT, type);
					return;
				default:
					break;
			}

			// All other events are simple presses.
			if (type != Manette.EventType.EVENT_BUTTON_PRESS) {
				return;
			}

			switch (button) {
				case EventCode.BTN_SOUTH:
					if (gamepad_type == GamepadType.NINTENDO) {
						handle_button_actions("btn.south", "gamepad.back");
					}
					else {
						handle_button_actions("btn.south", "gamepad.primary");
					}
					break;
				case EventCode.BTN_EAST:
					if (gamepad_type == GamepadType.NINTENDO) {
						handle_button_actions("btn.east", "gamepad.primary");
					}
					else {
						handle_button_actions("btn.east", "gamepad.back");
					}
					break;
				case EventCode.BTN_WEST:
					if (gamepad_type == GamepadType.NINTENDO) {
						handle_button_actions("btn.west", "gamepad.tertiary");
					}
					else {
						handle_button_actions("btn.west", "gamepad.secondary");
					}
					break;
				case EventCode.BTN_NORTH:
					if (gamepad_type == GamepadType.NINTENDO) {
						handle_button_actions("btn.north", "gamepad.secondary");
					}
					else {
						handle_button_actions("btn.north", "gamepad.tertiary");
					}
					break;

				case EventCode.BTN_SELECT:
					handle_button_actions("btn.select", "gamepad.overview");
					break;
				case EventCode.BTN_START:
					handle_button_actions("btn.start", "gamepad.options");
					break;
				case EventCode.BTN_MODE:
					handle_button_actions("btn.menu", "gamepad.menu");
					break;
				default:
					//debug("Unhandled button press: 0x%x", (int)button);
					break;
			}
		}
	}
}
