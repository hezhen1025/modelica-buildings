#!/usr/bin/env python3
#######################################################
# Script the installs spawn, which generates
# an FMU with the EnergyPlus envelope model
#######################################################
import os

from multiprocessing import Pool

import tempfile
import tarfile
import zipfile
import urllib.request, urllib.parse, urllib.error
import shutil

# Commit, see https://gitlab.com/kylebenne/spawn/-/pipelines?scope=all&page=1
# Also available is latest/Spawn-latest-{Linux,win64,Darwin}
# The setup below will lead to a specific commits being pulled.

###########################################################################
# List of all spawn versions and commits that are supported
# by the Buildings library
spawn_dists = [
    {"version": "0.3.0",
     "commit": "59ed8c72e47b646e71a3c4d1add8946968a333b2"}
]
###########################################################################

def log(msg):
    print(msg)


def get_bin_directory():
    file_path = os.path.dirname(os.path.realpath(__file__))
    return os.path.abspath(
        os.path.join(file_path, "..", "..", "..", "..", "Resources", "bin")
    )


def download_distribution(dis):
    tar_fil = os.path.basename(dis["src"])
    # Download the file
    log("Downloading {}".format(dis["src"]))
    urllib.request.urlretrieve(dis["src"], tar_fil)


def install_distribution_inside_buildings_library(dis):
    import glob

    des_dir = os.path.join(get_bin_directory(), dis["des"])
    if os.path.exists(des_dir):
        shutil.rmtree(des_dir)

    tar_fil = os.path.basename(dis["src"])

    delete_tar = False

    #log("Extracting {}".format(tar_fil))
    if tar_fil.endswith(".zip"):
        # Make a tar.gz out of it.
        with tempfile.TemporaryDirectory(prefix="tmp-Buildings-inst") as zip_dir:
            with zipfile.ZipFile(tar_fil, "r") as zip_ref:
                zip_ref.extractall(zip_dir)
            curDir = os.path.abspath(os.path.curdir)
            new_name = os.path.join(curDir, tar_fil[:-3] + "tar.gz")
            os.chdir(zip_dir)
            with tarfile.open(new_name, "w") as t:
                t.add(".")
            os.chdir(curDir)
        delete_tar = True # At end, delete the zip file
        tar_fil = new_name

    # Extract files
    tar = tarfile.open(tar_fil)
    with tempfile.TemporaryDirectory(prefix="tmp-Buildings-inst-") as tar_dir:

        tar.extractall(tar_dir)
        src = os.path.join(tar_dir, os.path.basename(tar_fil[0:-7]))

        # Move files
        if not os.path.exists(des_dir):
            os.makedirs(des_dir, exist_ok=True)
        for file in os.listdir(src):
            file_name = os.path.join(src, file)
            shutil.move(file_name, des_dir)
    tar.close()

    # Delete created tar.gz file
    if delete_tar:
        os.remove(tar_fil)

    print(f"Wrote {des_dir}")

def delete_installers(dis):
    tar_fil = os.path.basename(dis["src"])
    os.remove(tar_fil)

def get_vars_as_json(spawnFlag, spawn_dir, spawn_exe):
    """Return a json structure that contains the output variables supported by spawn"""
    import os
    import subprocess
    import json

    bin_dir = get_bin_directory()
    spawn = os.path.join(bin_dir, spawn_dir, "linux64", "bin", spawn_exe)

    ret = subprocess.run([spawn, spawnFlag], stdout=subprocess.PIPE, check=True)
    vars = json.loads(ret.stdout)
    if spawnFlag == "--output-vars":
        vars = sorted(vars, key = lambda i: i['name'])
    else:
        vars = sorted(vars, key = lambda i: (i['componentType'], i['controlType']))
    return vars


def get_html_table(allVars, template_name):
    """Returns an html-formatted table with all variables in the json structure `allVars`,
    using the template `template_name`
    """
    import jinja2
    import os

    path_to_template = os.path.dirname(os.path.realpath(__file__))
    env = jinja2.Environment(loader=jinja2.FileSystemLoader(path_to_template))
    template = env.get_template(template_name)
    html = template.render(vars=allVars)
    return html


def replace_table_in_mo(html, varType, moFile, spawn_dir):
    """Replaces in the .mo file the table with the output variables"""
    import os
    import re

    energyPlus_version_dash = _getEnergyPlusVersion(spawn_dir).replace('.', '_')

    mo_name = os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        "..",
        "..",
        "..",
        "..",
        "ThermalZones",
        f"EnergyPlus_{energyPlus_version_dash}",
        moFile,
    )
    mo_new = ""
    with open(mo_name, "r") as mo_fil:
        mo_old = mo_fil.read()
        # Start and end anchors in the mo file
        staStr = f"<!-- Start of table of {varType} generated by install.py. Do not edit. -->"
        endStr = (
            f"<!-- End of table of {varType} generated by install.py. Do not edit. -->"
        )
        mo_new, count = re.subn(
            r"(?<=%s).*(?=%s)" % (staStr, endStr),
            f"\n{html}\n",
            mo_old,
            flags=re.MULTILINE | re.DOTALL,
        )
        # Raise an error if the table was not updated. (Updating the table with the same content won't raise an error.)
        if count == 0:
            raise RuntimeError(
                f"Failed to update list of {varType} in {mo_name}. File was not modified."
            )
    # Write new file.
    with open(mo_name, "w") as mo_fil:
        mo_fil.write(mo_new)


def _getEnergyPlusVersion(spawn_dir):
    """ Return the EnergyPlus version in the form 9.6.0
    """
    spawn_name = f"spawn-{version}-{commit[0:10]}"
    idd = os.path.abspath( \
            os.path.join(__file__, \
                os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, \
                "Buildings", "Resources", "bin", spawn_dir, "linux64", "etc", "Energy+.idd"))

    prefix="!IDD_Version "
    with open(idd, 'r') as f:
        lines = f.readlines()
        for lin in lines:
            if lin.find(prefix) > -1:
                versionString = lin[len(prefix):].strip()
                return versionString

    raise ValueError("Failed to find EnergyPlus version.")

def update_version_in_modelica_files(spawn_dir, spawn_exe):
    import os
    import re

    energyPlus_version = _getEnergyPlusVersion(spawn_dir)
    ep_package = f"EnergyPlus_{energyPlus_version}".replace('.', '_')

    for rel_file in [\
        os.path.join("Buildings", "ThermalZones", ep_package, "Building.mo"),
        os.path.join("Buildings", "ThermalZones", ep_package, "package.mo"),
        os.path.join("Buildings", "ThermalZones", ep_package, "UsersGuide.mo"),
        os.path.join("Buildings", "Resources", "Scripts", "travis", "pyfmi", "runSpawnFromOtherDirectory.py")
        ]:
        # Path to Building.mo
        abs_file = os.path.abspath( \
            os.path.join(__file__, \
                os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, \
                rel_file))

        # Replace the string "spawn-0.2.0-d7f1e095f3" with the current version
        with open (abs_file, 'r' ) as f:
            content = f.read()
        content = re.sub(r"spawn-\d+.\d+.\d+-.{10}", f"{spawn_exe}", content)
        content = re.sub(r"Spawn-light-\d+.\d+.\d+-.{10}", f"{spawn_dir}", content)
        content = re.sub(r"EnergyPlus \d+.\d+.\d+", f"EnergyPlus {energyPlus_version}", content)

        with open(abs_file, 'w' ) as f:
            f.write(content)


def update_actuator_output_tables(spawn_dir, spawn_exe):
    vars = [
        {
            "spawnFlag": "--output-vars",
            "htmlTemplate": "output_vars_template.html",
            "varType": "output variables",
            "moFile": "OutputVariable.mo"
        },
        {
            "spawnFlag": "--actuators",
            "htmlTemplate": "actuators_template.html",
            "varType": "actuators",
            "moFile": "Actuator.mo"
        },
    ]
    for v in vars:
        js = get_vars_as_json(v["spawnFlag"], spawn_dir, spawn_exe)
        html = get_html_table(js, v["htmlTemplate"])
        replace_table_in_mo(html, v["varType"], v["moFile"], spawn_dir)


#def update_git(spawn_exe):
#    import os
#    import glob
#    from git import Repo
#    import sys
#
#    git_folder = os.path.abspath( \
#        os.path.join(__file__, \
#            os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, os.pardir, ".git"))
#    repo = Repo(git_folder)
#
#    # Get the old Spawn executuables
#    for file in glob.glob(os.path.join("Buildings", "Resources", "bin", "**/spawn-?.?.?-*"), recursive=True):
#        if spawn_exe in file:
#            # Add to git
#            print(f"Adding {file} to git")
#            repo.index.add([file])
#        else:
#            print(f"Removing {file} from git")
#            if os.path.isdir(file):
#                repo.index.remove([file], r=True)
#                # Remove directory physically if it still exists.
#                if os.path.exists(file):
#                    shutil.rmtree(file)
#            else:
#                # The file may already have been removed if its directory was removed in this for loop
#                if os.path.exists(file):
#                    repo.index.remove([file])

if __name__ == "__main__":
    import sys
    import argparse
    import platform

    # Configure the argument parser
    parser = argparse.ArgumentParser(
        description='Install and updates files used by Spawn.',
        allow_abbrev=False)

    parser.add_argument("--binaries-for-os-only",
                        action="store_true",
                        help="Only install binaries needed for the current operating system.")

    # Parse the arguments
    args = parser.parse_args()

    on_linux = "Linux" in platform.system()
    on_windows = "Windows" in platform.system()
    install_linux = on_linux     or not args.binaries_for_os_only
    install_windows = on_windows or not args.binaries_for_os_only
    update_mo_files = on_linux and not args.binaries_for_os_only

    # Build list of distributions
    dists = list()
    for spawn_dist in spawn_dists:
        version = spawn_dist['version']
        commit = spawn_dist['commit']
        if install_linux:
            dists.append(
               {
                    "src": f"https://spawn.s3.amazonaws.com/builds/Spawn-light-{version}-{commit[0:10]}-Linux.tar.gz",
                    "des": f"Spawn-light-{version}-{commit[0:10]}/linux64",
                    "spawn_dir": f"Spawn-light-{version}-{commit[0:10]}",
                    "spawn_exe": f"spawn-{version}-{commit[0:10]}",
                }
            )
        if install_windows:
            dists.append(
                {
                    "src": f"https://spawn.s3.amazonaws.com/builds/Spawn-light-{version}-{commit[0:10]}-win64.zip",
                    "des": f"Spawn-light-{version}-{commit[0:10]}/win64",
                    "spawn_exe": f"spawn-{version}-{commit[0:10]}"
                }
            )

    p = Pool(2)
    p.map(download_distribution, dists)
    for dist in dists:
        install_distribution_inside_buildings_library(dist)
        delete_installers(dist)

        # Update version in
        # constant String spawnExe="spawn-0.2.0-d7f1e095f3" ...
        # The version number needs to be only updated for Linux as Windows uses the same .mo files
        if update_mo_files and 'linux' in dist['des']:
            print("Updating Spawn version in Modelica files.")
            update_version_in_modelica_files(
                spawn_dir = dist["spawn_dir"],
                spawn_exe = dist["spawn_exe"])
        # Update the table with supported output variables and actuator names
        if update_mo_files and 'linux' in dist['des']:
            print("Updating actuator and output tables.")
            update_actuator_output_tables(
                spawn_dir = dist["spawn_dir"],
                spawn_exe = dist["spawn_exe"])


    # Remove old binaries and add new binaries to git
    #update_git(spawn_exe)
