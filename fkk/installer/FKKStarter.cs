// FKK Edition starter: checks for an update, installs it, then starts generalszh.exe.
// Compiled in CI with the .NET Framework csc (C# 5).
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using System.Drawing;

[assembly: System.Reflection.AssemblyTitle("FKK Edition Starter")]
[assembly: System.Reflection.AssemblyProduct("C&C Generals Zero Hour - FKK Edition")]

static class FKKStarter
{
	const string ReleaseBase = "https://github.com/SkewEB/GeneralsGameCode/releases/latest/download/";
	const string VersionFile = "fkk-version.txt";
	const string SetupFile = "FKK-Setup.exe";
	const string HashFile = "FKK-Setup.exe.sha256";
	const string GameExe = "generalszh.exe";

	[STAThread]
	static int Main(string[] args)
	{
		string dir = AppDomain.CurrentDomain.BaseDirectory;
		bool skipUpdate = Array.IndexOf(args, "-noupdate") >= 0;

		Application.EnableVisualStyles();
		Form splash = ShowSplash();
		DateTime splashUntil = DateTime.Now.AddSeconds(2.5);

		if (!skipUpdate)
		{
			try
			{
				if (TryUpdate(dir, splash))
					return 0; // setup takes over and restarts the starter afterwards
			}
			catch (Exception)
			{
				// offline or server unreachable: just start the installed version
			}
		}

		while (splash.Visible && DateTime.Now < splashUntil)
		{
			Application.DoEvents();
			Thread.Sleep(30);
		}
		splash.Close();

		string game = Path.Combine(dir, GameExe);
		if (!File.Exists(game))
		{
			MessageBox.Show(GameExe + " nicht gefunden in\n" + dir, "FKK Edition", MessageBoxButtons.OK, MessageBoxIcon.Error);
			return 1;
		}

		var psi = new ProcessStartInfo(game);
		psi.WorkingDirectory = dir;
		psi.UseShellExecute = false;
		var passArgs = new System.Collections.Generic.List<string>();
		foreach (string a in args) if (a != "-noupdate") passArgs.Add(a.Contains(" ") ? "\"" + a + "\"" : a);
		psi.Arguments = string.Join(" ", passArgs.ToArray());
		Process.Start(psi);
		return 0;
	}

	static Form ShowSplash()
	{
		Form f = new Form();
		f.FormBorderStyle = FormBorderStyle.None;
		f.StartPosition = FormStartPosition.CenterScreen;
		f.BackColor = Color.FromArgb(30, 33, 32);
		f.ClientSize = new Size(520, 300);
		f.ShowInTaskbar = true;
		f.Text = "Generals FKK Edition";
		f.TopMost = true;

		Stream logoStream = typeof(FKKStarter).Assembly.GetManifestResourceStream("fkk-logo.png");
		if (logoStream != null)
		{
			PictureBox pic = new PictureBox();
			pic.Image = Image.FromStream(logoStream);
			pic.SizeMode = PictureBoxSizeMode.Zoom;
			pic.BackColor = Color.Transparent;
			pic.SetBounds(60, 24, 400, 162);
			f.Controls.Add(pic);
		}

		Label title = new Label();
		title.Text = "Fliesen Kalisch Killer Edition";
		title.ForeColor = Color.FromArgb(230, 40, 40);
		title.Font = new Font("Segoe UI", 20f, FontStyle.Bold);
		title.TextAlign = ContentAlignment.MiddleCenter;
		title.SetBounds(0, 196, 520, 44);
		f.Controls.Add(title);

		Label sub = new Label();
		sub.Text = "Command & Conquer Generals Zero Hour";
		sub.ForeColor = Color.FromArgb(200, 200, 200);
		sub.Font = new Font("Segoe UI", 11f);
		sub.TextAlign = ContentAlignment.MiddleCenter;
		sub.SetBounds(0, 242, 520, 26);
		f.Controls.Add(sub);

		f.Show();
		f.Refresh();
		Application.DoEvents();
		return f;
	}

	static bool TryUpdate(string dir, Form splash)
	{
		ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; // TLS 1.2

		string local = "";
		string localFile = Path.Combine(dir, VersionFile);
		if (File.Exists(localFile))
			local = File.ReadAllText(localFile).Trim();

		string remote;
		using (var wc = new TimeoutWebClient(8000))
			remote = wc.DownloadString(ReleaseBase + VersionFile).Trim();

		// the version is the game build commit (short sha); anything else is rejected
		if (!Regex.IsMatch(remote, "^[0-9a-f]{7,40}$") || remote == local)
			return false;

		// expected SHA-256 of FKK-Setup.exe, published by the installer workflow next to it
		string expectedHash;
		using (var wc = new TimeoutWebClient(8000))
			expectedHash = wc.DownloadString(ReleaseBase + HashFile).Trim().Split(' ')[0].ToLowerInvariant();
		if (!Regex.IsMatch(expectedHash, "^[0-9a-f]{64}$"))
			return false;

		// leftovers of earlier updates
		try
		{
			foreach (string old in Directory.GetDirectories(Path.GetTempPath(), "FKK-Update-*"))
				try { Directory.Delete(old, true); } catch (Exception) { }
		}
		catch (Exception) { }

		// private download folder of this user, fresh for every update
		string updateDir = Path.Combine(Path.GetTempPath(), "FKK-Update-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(updateDir);
		string setup = Path.Combine(updateDir, "FKK-Setup-" + remote + ".exe");
		splash.Hide();

		Form form = new Form();
		form.Text = "FKK Edition";
		form.FormBorderStyle = FormBorderStyle.FixedDialog;
		form.StartPosition = FormStartPosition.CenterScreen;
		form.ClientSize = new Size(380, 90);
		form.MaximizeBox = false;
		form.MinimizeBox = false;
		Label label = new Label();
		label.Text = "Update auf " + remote + " wird geladen ...";
		label.SetBounds(12, 12, 356, 20);
		ProgressBar bar = new ProgressBar();
		bar.SetBounds(12, 44, 356, 22);
		form.Controls.Add(label);
		form.Controls.Add(bar);

		Exception error = null;
		bool done = false;
		WebClient dl = new WebClient();
		dl.DownloadProgressChanged += delegate(object s, DownloadProgressChangedEventArgs e) { bar.Value = Math.Max(0, Math.Min(100, e.ProgressPercentage)); };
		dl.DownloadFileCompleted += delegate(object s, System.ComponentModel.AsyncCompletedEventArgs e) { error = e.Error; done = true; form.Close(); };
		form.Shown += delegate { dl.DownloadFileAsync(new Uri(ReleaseBase + SetupFile), setup); };
		form.FormClosing += delegate(object s, FormClosingEventArgs e) { if (!done) dl.CancelAsync(); };
		Application.Run(form);

		if (!done || error != null || !File.Exists(setup))
		{
			splash.Show();
			return false; // cancelled or failed: start the old version
		}

		// Lock the file against writes while it is checked and started, so nothing can swap
		// it between the hash check and the admin prompt. Windows can still read and run it.
		FileStream locked = new FileStream(setup, FileMode.Open, FileAccess.Read, FileShare.Read);
		try
		{
			string actualHash;
			using (SHA256 sha = SHA256.Create())
				actualHash = BitConverter.ToString(sha.ComputeHash(locked)).Replace("-", "").ToLowerInvariant();
			if (actualHash != expectedHash)
			{
				locked.Dispose();
				locked = null;
				try { File.Delete(setup); } catch (Exception) { }
				splash.Hide();
				MessageBox.Show("Das heruntergeladene Update ist beschaedigt oder wurde veraendert und wird nicht installiert.\nDas Spiel startet mit der bisherigen Version.",
					"FKK Edition", MessageBoxButtons.OK, MessageBoxIcon.Warning);
				splash.Show();
				return false;
			}
			return StartSetup(setup, splash);
		}
		finally
		{
			if (locked != null)
				locked.Dispose();
		}
	}

	static bool StartSetup(string setup, Form splash)
	{
		var psi = new ProcessStartInfo(setup);
		psi.Arguments = "/SILENT /SUPPRESSMSGBOXES /NORESTART /FKKUPDATE=1";
		psi.UseShellExecute = true;
		psi.Verb = "runas";
		try
		{
			Process.Start(psi);
		}
		catch (System.ComponentModel.Win32Exception)
		{
			splash.Show();
			return false; // admin prompt declined
		}
		return true;
	}

	class TimeoutWebClient : WebClient
	{
		readonly int m_timeout;
		public TimeoutWebClient(int timeout) { m_timeout = timeout; }
		protected override WebRequest GetWebRequest(Uri address)
		{
			WebRequest r = base.GetWebRequest(address);
			r.Timeout = m_timeout;
			return r;
		}
	}
}
