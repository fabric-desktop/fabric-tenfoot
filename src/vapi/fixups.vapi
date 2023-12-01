[CCode (cprefix = "Gtk", gir_namespace = "Gtk", gir_version = "4.0", lower_case_cprefix = "gtk_")]
// Namespace to override broken function signatures.
namespace GtkFIXED {
	[CCode (cheader_filename = "gtk/gtk.h", ref_function = "gtk_expression_ref", type_id = "gtk_expression_get_type ()", unref_function = "gtk_expression_unref")]
	public abstract class Expression {
		// https://gitlab.gnome.org/GNOME/vala/-/commit/f8ebed0b3449718b6e89def52855c668a88ebcc6
		public bool evaluate (GLib.Object? this_, ref GLib.Value value);
	}
}
