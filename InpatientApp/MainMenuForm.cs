using System;
using System.Drawing;
using System.Windows.Forms;

namespace InpatientApp
{
    /// <summary>
    /// Main menu: one button per screen + connection status.
    /// The other team members' forms are opened by class name, so this file
    /// compiles even before those forms exist. When a form class (for example
    /// PatientsForm) is added to the project, its button starts working automatically.
    /// </summary>
    public class MainMenuForm : Form
    {
        // Colors shared by the whole program (other screens can reuse them)
        public static readonly Color Primary   = Color.FromArgb(15, 76, 110);
        public static readonly Color Accent    = Color.FromArgb(0, 150, 160);
        public static readonly Color Background = Color.FromArgb(240, 245, 248);

        private Label lblStatus;

        // Button text -> class name of the screen it opens
        private static readonly string[,] Screens =
        {
            { "Patients",              "PatientsForm" },
            { "Admission && Discharge", "AdmissionForm" },
            { "Departments / Doctors", "DoctorsForm" },
            { "Rooms && Beds",          "RoomsBedsForm" },
            { "Services / Labs",       "ServicesLabsForm" },
            { "Admission Services",    "AdmissionServicesForm" },
            { "Search && Reports",      "ReportsForm" },
        };

        public MainMenuForm()
        {
            Text = "Inpatient Management System";
            ClientSize = new Size(860, 640);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            BackColor = Background;
            Font = new Font("Segoe UI", 10F);

            BuildHeader();
            BuildButtons();
            BuildFooter();

            Shown += (s, e) => RefreshStatus();
        }

        private void BuildHeader()
        {
            Panel header = new Panel { Dock = DockStyle.Top, Height = 110, BackColor = Primary };

            Label title = new Label
            {
                Text = "Inpatient Management System",
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 24F, FontStyle.Bold),
                AutoSize = true,
                Location = new Point(30, 20)
            };
            Label subtitle = new Label
            {
                Text = "Patients  |  Admissions  |  Beds  |  Doctors  |  Services",
                ForeColor = Color.FromArgb(200, 225, 235),
                Font = new Font("Segoe UI", 11F),
                AutoSize = true,
                Location = new Point(34, 70)
            };
            header.Controls.Add(title);
            header.Controls.Add(subtitle);
            Controls.Add(header);
        }

        private void BuildButtons()
        {
            int btnW = 380, btnH = 70, gapX = 20, gapY = 20;
            int startX = 40, startY = 140;

            for (int i = 0; i < Screens.GetLength(0); i++)
            {
                int col = i % 2, row = i / 2;
                string screenClass = Screens[i, 1];
                string text = Screens[i, 0];

                Button b = MakeButton(text.Replace("&&", "&"), Primary);
                b.Size = new Size(btnW, btnH);
                b.Location = new Point(startX + col * (btnW + gapX), startY + row * (btnH + gapY));
                b.Click += (s, e) => OpenScreen(screenClass, text.Replace("&&", "&"));
                Controls.Add(b);
            }

            // Exit button (centered on the last row)
            int exitRow = (Screens.GetLength(0) + 1) / 2;
            Button exit = MakeButton("Exit", Color.FromArgb(170, 50, 50));
            exit.Size = new Size(btnW, btnH);
            exit.Location = new Point(startX + (Screens.GetLength(0) % 2 == 0 ? 0 : btnW + gapX),
                                      startY + (Screens.GetLength(0) % 2 == 0 ? exitRow : exitRow - 1) * (btnH + gapY));
            exit.Click += (s, e) => Close();
            Controls.Add(exit);
        }

        private Button MakeButton(string text, Color color)
        {
            Button b = new Button
            {
                Text = text,
                BackColor = color,
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 13F, FontStyle.Bold),
                Cursor = Cursors.Hand
            };
            b.FlatAppearance.BorderSize = 0;
            b.FlatAppearance.MouseOverBackColor = Accent;
            return b;
        }

        private void BuildFooter()
        {
            Panel footer = new Panel { Dock = DockStyle.Bottom, Height = 44, BackColor = Color.White };

            lblStatus = new Label
            {
                AutoSize = false,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(20, 0, 0, 0),
                Text = "Checking database connection..."
            };

            Button retry = new Button
            {
                Text = "Test connection",
                Dock = DockStyle.Right,
                Width = 150,
                FlatStyle = FlatStyle.Flat
            };
            retry.Click += (s, e) => RefreshStatus();

            footer.Controls.Add(lblStatus);
            footer.Controls.Add(retry);
            Controls.Add(footer);
        }

        private void RefreshStatus()
        {
            string msg;
            bool ok = Database.TestConnection(out msg);
            lblStatus.Text = "● " + msg;
            lblStatus.ForeColor = ok ? Color.FromArgb(0, 128, 60) : Color.FromArgb(180, 40, 40);
        }

        /// <summary>Opens a screen by its class name; hides the menu until it is closed.</summary>
        private void OpenScreen(string className, string title)
        {
            Type t = Type.GetType("InpatientApp." + className);
            if (t == null)
            {
                MessageBox.Show("The \"" + title + "\" screen is not added to the project yet.",
                                "Coming soon", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            Form screen = (Form)Activator.CreateInstance(t);
            Hide();
            screen.FormClosed += (s, e) => Show();
            screen.Show();
        }
    }
}
