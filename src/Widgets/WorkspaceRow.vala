/*
 * Copyright (c) 2020 - Today Goncalo Margalho (https://github.com/devalien)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Goncalo Margalho <g@margalho.info>
 */

public class Workspaces.Widgets.WorkspaceRow : Gtk.ListBoxRow {
    public Workspaces.Models.Workspace workspace { get; construct; }
    public Gtk.ScrolledWindow scrolled { get; set; }

    private Gtk.Image area_image;
    private Gtk.Button submit_button;
    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.EventBox top_eventbox;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer motion_workspace_revealer;
    private Gtk.Grid drop_grid;
    private Gtk.Revealer action_revealer;
    public Gtk.Revealer main_revealer;

    public bool is_open {get; set; default = true;}

    public signal void added_new_item (Workspaces.Widgets.ItemRow item);
    public signal void item_deleted (Workspaces.Widgets.WorkspaceItem item);

    private const Gtk.TargetEntry[] TARGET_ITEMS = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_WORKSPACES = {
        {"WORKSPACEROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool set_focus {
        set {
            submit_button.sensitive = true;
            action_revealer.reveal_child = true;
            name_stack.visible_child_name = "name_entry";

            name_entry.grab_focus_without_selecting ();
            if (name_entry.cursor_position < name_entry.text_length) {
                name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32)name_entry.text_length, false);
            }
        }
    }

    public WorkspaceRow (Workspaces.Models.Workspace workspace) {
        Object (workspace: workspace

                );
    }

    construct {
        get_style_context ().add_class ("workspace-row");

        area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.CENTER;
        area_image.valign = Gtk.Align.CENTER;
        area_image.pixel_size = 20;
        area_image.margin_end = 4;

        if (workspace.icon != null) {
            try {
                area_image.gicon = Icon.new_for_string (workspace.icon);
            } catch (Error e) {
                debug (e.message);
            }
        } else {
            area_image.set_visible (false);
        }

        var menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("view-more-symbolic");
        menu_image.pixel_size = 14;

        var edit_menuitem = new Gtk.ModelButton ();
        edit_menuitem.text = _ ("Edit");
        edit_menuitem.clicked.connect (() => {
            Application.instance.preferences_window.load_workspace (this);
        });
        var delete_menuitem = new Gtk.ModelButton ();
        delete_menuitem.text = _ ("Delete");
        delete_menuitem.get_style_context ().add_class ("menu-danger");
        delete_menuitem.clicked.connect (() => {
            Application.instance.preferences_window.delete_workspace_dialog (this);
        });
        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.margin_top = 5;
        menu_grid.row_spacing = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.attach (edit_menuitem, 0,0, 3, 1);
        menu_grid.attach (new Gtk.SeparatorMenuItem (), 0, 1, 3, 1);
        menu_grid.attach (delete_menuitem, 0, 2, 3, 1);
        menu_grid.show_all ();

        var menu = new Gtk.Popover (null);
        menu.set_position (Gtk.PositionType.LEFT);
        menu.add (menu_grid);

        var menu_button = new Gtk.MenuButton ();
        menu_button.can_focus = false;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.tooltip_text = _ ("Section Menu");
        menu_button.image = menu_image;
        menu_button.popover = menu;

        menu_button.get_style_context ().remove_class ("button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("hidden-button");
        menu.set_position (Gtk.PositionType.LEFT);

        name_label = new Gtk.Label (workspace.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("left-list-label");
        name_label.get_style_context ().add_class ("bold-label");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 10;
        top_box.margin_end = 5;
        top_box.margin_top = 1;
        top_box.margin_bottom = 1;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_label, false, true, 0);
        top_box.pack_end (menu_button, false, false, 0);


        top_eventbox = new Gtk.EventBox ();

        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = true;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 6;
        separator.margin_end = 6;

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 6;
        motion_grid.margin_end = 6;
        motion_grid.height_request = 24;
        motion_grid.get_style_context ().add_class ("grid-motion");

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        drop_grid = new Gtk.Grid ();
        drop_grid.margin_start = 6;
        drop_grid.margin_end = 6;
        drop_grid.height_request = 12;
        drop_grid.get_style_context ().add_class ("drop_grid");

        var motion_workspace_grid = new Gtk.Grid ();
        motion_workspace_grid.margin_top = 6;
        motion_workspace_grid.margin_start = 6;
        motion_workspace_grid.margin_end = 6;
        motion_workspace_grid.height_request = 24;
        motion_workspace_grid.margin_bottom = 12;
        motion_workspace_grid.get_style_context ().add_class ("grid-motion");

        motion_workspace_revealer = new Gtk.Revealer ();
        motion_workspace_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_workspace_revealer.add (motion_workspace_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("workspace-item");
        main_box.hexpand = true;
        main_box.pack_start (top_eventbox, false, false, 0);
        //  main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);
        main_box.pack_start (drop_grid, false, false, 0);
        main_box.pack_start (motion_workspace_revealer, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_box);
        foreach ( var item in workspace.items ) {
            add_item (item, false);
        }

        add (main_revealer);

        build_drag_and_drop ();

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                Application.instance.unselect_all_items (this);
                var item = ((Workspaces.Widgets.ItemRow)row);
                Application.instance.preferences_window.load_item (item);
            }
        });

        Application.instance.unselect_all_items.connect ((workspace_row) => {
            if (this != workspace_row) {
                listbox.unselect_all ();
            }
        });

        workspace.item_added.connect ((item) => {
            add_item (item, true);
        });

        show_all ();
    }

    public void set_icon (GLib.Icon icon) {
        area_image.gicon = icon;
        area_image.set_visible (true);
    }

    public void set_label (string label) {
        name_label.label = label;
    }

    private void add_item (Workspaces.Models.Item item, bool to_open) {
        var it = new Workspaces.Widgets.ItemRow (item);
        listbox.add (it);
        if (to_open) {
            Application.instance.preferences_window.workspaces_list.select_row (this);
            listbox.select_row (it);
        }
    }


    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_WORKSPACES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        Gtk.drag_dest_set (drop_grid, Gtk.DestDefaults.MOTION, TARGET_WORKSPACES, Gdk.DragAction.MOVE);
        drop_grid.drag_motion.connect (on_drag_area_motion);
        drop_grid.drag_leave.connect (on_drag_area_leave);
        //  drop_grid.drag_data_received.connect (on_drag_data_received_workspace);

        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ITEMS, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (top_eventbox, Gtk.DestDefaults.ALL, TARGET_ITEMS, Gdk.DragAction.MOVE);
        top_eventbox.drag_data_received.connect (on_drag_item_received);
        top_eventbox.drag_motion.connect (on_drag_motion);
        top_eventbox.drag_leave.connect (on_drag_leave);
    }

    public bool on_drag_area_motion (Gdk.DragContext context, int x, int y, uint time) {
        debug ("on_drag_area_motion");
        motion_workspace_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_area_leave (Gdk.DragContext context, uint time) {
        debug ("on_drag_area_leave");
        motion_workspace_revealer.reveal_child = false;
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Workspaces.Widgets.WorkspaceRow)widget).top_eventbox;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.5);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.get_style_context ().add_class ("drag-begin");
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
                                   Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Workspaces.Widgets.WorkspaceRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("WORKSPACEROW"), 32, data
            );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
                                        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Workspaces.Widgets.ItemRow target;
        Workspaces.Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Workspaces.Widgets.ItemRow)listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[])selection_data.get_data ())[0];
        source = (Workspaces.Widgets.ItemRow)row;

        if (target != null) {
            source.get_parent ().remove (source);
            Application.instance.workspaces_controller.remove_item (source.item);

            listbox.insert (source, target.get_index () + 1);
            Application.instance.workspaces_controller.insert_item (source.item, workspace, target.get_index () + 1);

            listbox.show_all ();
        }
    }


    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
                                        Gtk.SelectionData selection_data, uint target_type) {
        Workspaces.Widgets.ItemRow source;

        var row = ((Gtk.Widget[])selection_data.get_data ())[0];
        source = (Workspaces.Widgets.ItemRow)row;

        listbox.remove (source);
        Application.instance.workspaces_controller.remove_item (source.item);

        listbox.insert (source, 0);
        Application.instance.workspaces_controller.insert_item (source.item, workspace, 0);

        listbox.show_all ();
        listbox_revealer.reveal_child = true;
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    public void remove_itself () {
        var has_deleted = Application.instance.workspaces_controller.remove_workspace (workspace);
        if (has_deleted) {
            get_parent ().remove (this);
        }
    }
}