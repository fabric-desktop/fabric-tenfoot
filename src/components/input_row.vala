namespace Fabric.Tenfoot {
	public class InputRow : Gtk.Grid {
		private const int RATIO_LABEL = 7;
		private const int RATIO_WIDGET = 5;

		protected Gtk.Label label_widget;
		protected Gtk.Widget _widget;

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
					remove(_widget);
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
			}
		}

		public InputRow(string label) {
			add_css_class("tenfoot-input-row");
			label_widget = new Gtk.Label(label) {
				hexpand = true,
				halign = Gtk.Align.START,
			};
			label_widget.add_css_class("label");
			attach(label_widget, 1, 1, RATIO_LABEL);
		}

		construct {
			hexpand = true;
			halign = Gtk.Align.FILL;
			column_homogeneous = true;
		}

		protected new void attach(Gtk.Widget widget, int column, int row, int width = 1, int height = 1) {
			base.attach(widget, column, row, width, height);
		}
	}
}
