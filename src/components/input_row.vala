namespace Fabric.Tenfoot {
	public class InputRow : Gtk.Widget {
		private const int RATIO_LABEL = 7;
		private const int RATIO_WIDGET = 5;

		protected Gtk.Label _label;
		protected Gtk.Widget _widget;
		protected Gtk.Grid _grid;
		protected Gtk.Orientation responsive_mode {
			get; set; default = Gtk.Orientation.HORIZONTAL;
		}

		public static double narrow_boundary {
			get; set; default = 420;
		}

		private bool can_expand_widget(Gtk.Widget widget) {
			if (widget.get_type().is_a(typeof (Gtk.Switch))) {
				return false;
			}
			if (widget.get_type().is_a(typeof (Gtk.Button))) {
				return false;
			}
			return true;
		}

		public Gtk.Widget widget {
			get { return _widget; }
			set {
				if (_widget != null) {
					_grid.remove(_widget);
				}
				_widget = value;
				if (can_expand_widget(value)) {
					_widget.hexpand = true;
					_widget.halign = Gtk.Align.FILL;
				}
				else {
					_widget.hexpand = false;
					_widget.halign = Gtk.Align.END;
				}
				attach(_widget, RATIO_LABEL+0, 1, RATIO_WIDGET);
				responsive_relayout();
			}
		}

		public InputRow(string label) {
			hexpand = true;
			halign = Gtk.Align.FILL;

			_grid = new Gtk.Grid() {
				hexpand = true,
				halign = Gtk.Align.FILL,
				column_homogeneous = true,
			};
			_grid.set_parent(this);

			add_css_class("tenfoot-input-row");
			_label = new Gtk.Label(label) {
				hexpand = true,
				halign = Gtk.Align.START,
			};
			_label.add_css_class("label");
			attach(_label, 1, 1, RATIO_LABEL);

			notify["responsive-mode"].connect(this.responsive_relayout);

			GLib.Idle.add_once(() => {
				var application = (Application)GLib.Application.get_default();
				
				relayout_for(application.active_window.default_width);
			});
		}

		public override void size_allocate(int width, int height, int baseline) {
			relayout_for(width);
			// Silence a bogus warning...
			_grid.measure(Gtk.Orientation.HORIZONTAL, -1, null, null, null, null);
			_grid.allocate(width, height, baseline, null);
		}

		public override Gtk.SizeRequestMode get_request_mode() {
			return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
		}

		public override void measure(
			Gtk.Orientation orientation
			, int for_size
			, out int minimum
			, out int natural
			, out int minimum_baseline
			, out int natural_baseline
		) {
			if (orientation == Gtk.Orientation.HORIZONTAL && for_size != -1) {
				relayout_for(for_size);
			}

			_grid.measure(orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
		}

		protected new void attach(Gtk.Widget widget, int column, int row, int width = 1, int height = 1) {
			_grid.attach(widget, column, row, width, height);
		}

		protected void relayout_for(int width) {
			if (Fabric.UI.Application.scale_physical_to_logical(width) > narrow_boundary) {
				if (responsive_mode != Gtk.Orientation.HORIZONTAL) {
					responsive_mode = Gtk.Orientation.HORIZONTAL;
				}
			}
			else {
				if (responsive_mode != Gtk.Orientation.VERTICAL) {
					responsive_mode = Gtk.Orientation.VERTICAL;
				}
			}
		}

		protected void responsive_relayout() {
			GLib.Idle.add_once(this._responsive_relayout);
		}

		protected void _responsive_relayout() {
			if (_widget == null) { return; }

			bool regrab = get_focus_child() != null;
			if (responsive_mode == Gtk.Orientation.HORIZONTAL && !has_css_class("-is-horizontal")) {
				_grid.remove(_widget);
				remove_css_class("-is-vertical");
				add_css_class("-is-horizontal");
				attach(_widget, RATIO_LABEL+0, 1, RATIO_WIDGET);
				if (!can_expand_widget(_widget)) {
					_widget.halign = Gtk.Align.END;
				}
			}
			else if (responsive_mode == Gtk.Orientation.VERTICAL && !has_css_class("-is-vertical")) {
				_grid.remove(_widget);
				remove_css_class("-is-horizontal");
				add_css_class("-is-vertical");
				attach(_widget, 1, 2, RATIO_LABEL);
				if (!can_expand_widget(_widget)) {
					_widget.halign = Gtk.Align.START;
				}
			}

			if (regrab) {
				_widget.grab_focus();
				GLib.Idle.add_once(() => {
					var application = (Application)GLib.Application.get_default();
					application.ensure_visible(this._widget);
				});
			}
		}

		public override void dispose() {
			_grid.unparent();
		}
	}
}
