# Glazier

Glazier is a set of batch files, scripts and toolchains designed to
ease building CouchDB on Windows. It's as fully automated as
possible, with most of the effort required only once.

Glazier uses the MS Visual Studio 2022 toolchain as much as possible,
to ensure a quality Windows experience and to execute all binary
dependencies within the same runtime.

We hope Glazier simplifies using Erlang and CouchDB for you, giving
a consistent, repeatable build environment.

Of course, you can also use our [previous script collection](README.OLD.md)
to create CouchDB for Windows. Please note that this is currently no longer
tested.

# Base Requirements

Note that the scripts you'll run will modify your system extensively. We recommend a *dedicated build machine or VM image* for this work:

- 64-bit Windows 7+. *As of CouchDB 2.0 we only support a 64-bit build of CouchDB*.
  - We like 64-bit Windows 10 Enterprise N (missing Media Player, etc.) from MSDN.
  - Apply Windows Updates and reboot until no more updates appear.
  - If using a VM, shutdown and snapshot your VM at this point.

# Install Dependencies

Start an Administrative PowerShell console. Enter the following:

```powershell
mkdir C:\relax\
cd C:\relax\
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation
choco install git
git config --global core.autocrlf false
git clone https://github.com/apache/couchdb-glazier
&.\couchdb-glazier\bin\install_dependencies.ps1
```

You should go get lunch. The last step will take over an hour, even on a speedy Internet connection.

At this point, you should have the following installed:

* Visual Studio 2022 (Build Tools, Visual C++ workload, native desktop workload)
* Windows 10 SDK (by native desktop workload; 10.0.19041.0)
* NodeJS (LTS version)
* WiX Toolset
* Python 3
  * Python packages sphinx, sphinx_rtd_theme, pygments, nose2 and hypothesis
* NSSM
* GNU make
* NuGet
* VSSetup
* VSWhere
* GNU CoreUtils (cp, rm, rmdir, ...)
* MozillaBuild setup
* VCPkg (https://github.com/Microsoft/vcpkg), which built and installed:
  * ICU (at time of writing, 69.1)

# Building SpiderMonkey

This section is not currently automated, due to the need for Mozilla's separate build
environment. It should be possible to automate (PRs welcome!). At time of writing, we
use the `esr91` branch of SpiderMonkey.

From the same PowerShell prompt, enter the following:

```powershell
C:\mozilla-build\start-shell.bat
```

At the MozillaBuild prompt, enter the following:

```bash
cd /c/relax
git clone https://github.com/mozilla/gecko-dev
cd gecko-dev
./mach bootstrap --application-choice js
git checkout esr91
```

Please answer the following questions of `./mach boostrap`.  Note that some of them may not show
up. You need this only for the first run. It downloads a complete build toolchain for
SpiderMonkey. You should run `./mach bootstrap` from the `master` branch and switch afterwards
to your explicit ESR branch!

* Would you like to create this directory? (Yn): Y
* Would you like to run a few configuration steps to ensure Git is optimally configured? (Yn): Y
* Will you be submitting commits to Mozilla? (Yn): n
* Would you like to enable build system telemetry? (Yn): n

On completely fresh Windows installs, it may happen that the necessary SSL certificates
are not yet stored on the system. This can cause that some of the files cannot be
downloaded over HTTPS. Open the URL https://static.rust-lang.org/ on Internet Explorer
and install the missing certificate to resolve this.

The build process may complain about clobbering (perhaps due to switching off from `master`).
In this case, create the `CLOBBER` file to silence the related warnings.

Now you should be set to launch the build.

```bash
export MOZCONFIG=/c/relax/couchdb-glazier/moz/sm-opt
./mach build
exit
```

Once finished, you should have built SpiderMonkey.
Back in PowerShell, copy the binaries to where our build process expects them:

```powershell
copy C:\relax\gecko-dev\sm-obj-opt\js\src\build\*.lib C:\relax\vcpkg\installed\x64-windows\lib
copy C:\relax\gecko-dev\sm-obj-opt\dist\bin\*.dll C:\relax\vcpkg\installed\x64-windows\bin
copy C:\relax\gecko-dev\sm-obj-opt\dist\include\* C:\relax\vcpkg\installed\x64-windows\include -Recurse -ErrorAction SilentlyContinue
```

Be sure to verify if all the components are built properly, especially the static library,
i.e. `mozjs-91.lib`, otherwise CouchDB will fail to build. In case anything is missing,
check the logs for errors and try searching for them on the [Mozilla Bug Tracker](https://bugzilla.mozilla.org/home).

Currently known problems:

- [lld-link: error: duplicate symbol: HeapAlloc](https://bugzilla.mozilla.org/show_bug.cgi?id=1802675)
- [JS shell build with --disable-jemalloc hits linker error with 2 DllMain](https://bugzilla.mozilla.org/show_bug.cgi?id=1751561)

# Building CouchDB itself

You're finally ready. You should snapshot your VM at this point!

Open a new PowerShell window. Set up your shell correctly (this step works if you've
closed your PowerShell window before any of the previous steps, too):

```powershell
&c:\relax\couchdb-glazier\bin\shell.ps1
```

Then, start the process:

```
cd c:\relax
git clone https://github.com/apache/couchdb
cd couchdb
git checkout <tag or branch of interest goes here>
&.\configure.ps1 -SpiderMonkeyVersion 91
make -f Makefile.win
```

You now have built CouchDB!

To run the tests:

```
make -f Makefile.win check
```

Finally, to build a CouchDB installer:

```
make -f Makefile.win release
cd c:\relax
&couchdb-glazier\bin\build_installer.ps1
```

The installer will be placed in your current working directory.

You made it! Time to relax. :D

If you're a release engineer, you may find the following commands useful too:

```
checksum -t sha256 apache-couchdb.#.#.#-RC#.tar.gz
checksum -t sha512 apache-couchdb.#.#.#-RC#.tar.gz
gpg --verify apache-couchdb.#.#.#-RC#.tar.gz.asc
```

# Appendices

## Why Glazier?

@dch first got involved with CouchDB around 0.7. Only having a low-spec Windows
PC to develop on, and no CouchDB Cloud provider being available, he tried
to build CouchDB himself. It was hard going, and most of the frustration was
trying to get the core Erlang environment set up and compiling without needing
to buy Microsoft's expensive but excellent Visual Studio tools. Once
Erlang was working he found many of the pre-requisite modules such as cURL,
Zlib, OpenSSL, Mozilla's SpiderMonkey JavaScript engine, and IBM's ICU were
not available at a consistent compiler and VC runtime release.

There is a branch of glazier that has been used to build each CouchDB release.

## Windows silent installs

Here are some sample commands, supporting the new features of the 3.0 installer.

Install CouchDB without a service, but with an admin user:password of `admin:hunter2`:

```
msiexec /i apache-couchdb-3.0.0.msi /quiet ADMINUSER=admin ADMINPASSWORD=hunter2 /norestart
```

The same as above, but also install and launch CouchDB as a service:

```
msiexec /i apache-couchdb-3.0.0.msi /quiet INSTALLSERVICE=1 ADMINUSER=admin ADMINPASSWORD=hunter2 /norestart
```

Unattended uninstall of CouchDB:

```
msiexec /x apache-couchdb-3.0.0.msi /quiet /norestart
```

Unattended uninstall if the installer file is unavailable:

```
msiexec /x {4CD776E0-FADF-4831-AF56-E80E39F34CFC} /quiet /norestart
```

Add `/l* log.txt` to any of the above to generate a useful logfile for debugging.
