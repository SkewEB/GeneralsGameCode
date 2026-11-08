// FKK Edition starter: checks for an update, installs it, then starts generalszh.exe.
// Compiled in CI with the .NET Framework csc (C# 5).
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
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
	const string GameExe = "generalszh.exe";

	[STAThread]
	static int Main(string[] args)
	{
		string dir = AppDomain.CurrentDomain.BaseDirectory;
		bool skipUpdate = Array.IndexOf(args, "-noupdate") >= 0;

		if (!skipUpdate)
		{
			try
			{
				if (TryUpdate(dir))
					return 0; // setup takes over and restarts the starter afterwards
			}
			catch (Exception)
			{
				// offline or server unreachable: just start the installed version
			}
		}

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

	static bool TryUpdate(string dir)
	{
		ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; // TLS 1.2

		string local = "";
		string localFile = Path.Combine(dir, VersionFile);
		if (File.Exists(localFile))
			local = File.ReadAllText(localFile).Trim();

		string remote;
		using (var wc = new TimeoutWebClient(8000))
			remote = wc.DownloadString(ReleaseBase + VersionFile).Trim();

		if (remote.Length == 0 || remote.Length > 64 || remote == local)
			return false;

		string setup = Path.Combine(Path.GetTempPath(), "FKK-Setup-" + remote + ".exe");

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
		Application.EnableVisualStyles();
		Application.Run(form);

		if (!done || error != null || !File.Exists(setup))
			return false; // cancelled or failed: start the old version

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
