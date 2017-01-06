#!/usr/bin/python
#####################################################################
# This script cleans up the html code generated by Dymola,
# and it adds the link to the style sheet
#
# MWetter@lbl.gov                                          2011-05-15
#####################################################################
import os, string, fnmatch, os.path, sys
from os import listdir
from os.path import isfile, join
import argparse


def validateLine(line, filNam):
    # MathJax should be served using https, not http
    li = ['/tmp/', \
          'home/mwetter', \
          'dymola/Modelica', \
          'Extends from <a href="file', \
          '///opt/dymola', \
          'github/lbl-srg', \
          '<a href="http://www.3ds.com/">Automatically generated</a>', \
          'http://cdn.mathjax.org/mathjax/latest/MathJax.js']
    em = ""
    for s in li:
        if s in line:
            em += "*** Error: Invalid string '%s' in file '%s'.\n" % (s, filNam)
    if len(em) > 0:
        raise ValueError(em)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description = 'Updates the html files generated by Dymola.',
        epilog = "Use as cleanHTML.py --library Buildings --homepage http://simulationresearch.lbl.gov/modelica")

    parser.add_argument(\
                        '--library',
                        help = 'Name of the library',
                        default = "Buildings",
                        dest = 'LIB_NAME')

    parser.add_argument(\
                        '--homepage',
                        help = 'URL to main site of the library, such as "http://simulationresearch.lbl.gov/modelica"',
                        default = "http://simulationresearch.lbl.gov/modelica",
                        dest = 'HOMEPAGE')
    
    args = parser.parse_args()

    # Parse arguments
    LIB_NAME = args.LIB_NAME
    HOMEPAGE = args.HOMEPAGE

    
    # --------------------------
    # Global settings
    LIBHOME=os.path.abspath(".")

    helpDir=LIBHOME + os.path.sep + 'help'

    files = [ f for f in listdir(helpDir) if f.endswith(".html") ]


    replacements = {'font-family: Arial, sans-serif;': '',
                    '</head>':
                    '''
  <!-- Bootstrap core CSS -->
  <link href="../Resources/www/css/bootstrap.min.css" rel="stylesheet">

  <!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
  <link href="../Resources/www/css/ie10-viewport-bug-workaround.css" rel="stylesheet">

  <!-- Custom styles for this template -->
  <link href="../Resources/www/css/custom.css" rel="stylesheet">

  <!-- Custom changes for Modelica -->
  <link href="../Resources/www/css/modelicaDoc.css" rel="stylesheet">

</head>
<body>
  <div id="navbar" class="navbar navbar-default ">
  <div class="container-fluid">
    <div class="navbar-header">
      <!-- .btn-navbar is used as the toggle for collapsed navbar content -->
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".nav-collapse">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="#"><img src="../Resources/www/library-logo.png" alt="Library logo">
         </a>
      <span class="navbar-text navbar-version pull-left"><b></b></span>
    </div>

    <div id="navbar" class="navbar-collapse collapse nav-collapse">

        <ul class="nav navbar-nav">
              <li><a href="{homepage}">Home</a></li>
              <li><a href="{library_name}.html">Modelica</a></li>
        </ul>
      </div>
  </div>
</div>
<div class="page-content">'''.format( \
                        library_name = LIB_NAME, homepage = HOMEPAGE),
                    LIBHOME:
                    '..',
                    '<pre></pre>':''}

    ##########################################
    # Discover the link to the html page of the msl, such as in
    # <p>Extends from <a href="file:////opt/dymola-2015FD01-x86_64-patch1/Modelica/Library/Modelica%203.2.1/help/Modelica_Icons_Package.html#Modelica.Icons.Package"
    #                          -----------------------------------------------------------------------
    # This is then used in the text replace below.
    # The test file that we search
    tesFil=os.path.join(LIBHOME, "help", "{}.html".format(LIB_NAME))
    insLoc = None
    with open(tesFil, 'r') as fil:
        lines = fil.readlines()
        for lin in lines:
            iSta = lin.find('Extends from <a href="file')
            if iSta > -1:
                s = "Library/"
                iEnd = lin.find(s) + len(s)
                # Get a string such as file:////opt/dymola-2015FD01-x86_64-patch1/Modelica/
                insLoc = lin[lin.find('href=')+6:iEnd]
                break
    
    if insLoc is not None:
        # Remove Library from a string such as file:////opt/dymola-2015FD01-x86_64-patch1/Modelica/Library
        # and add help/ExternalObject instead of
        repExtObj = insLoc[:len(insLoc)-len("Library")-1] + "help/ExternalObject"
        replacements[repExtObj] = insLoc + "ExternalObject/ExternalObject"
        replacements['%s' % (insLoc)] = '../../msl/'

        
    # Search for text such as
    # <img alt="image" src="/tmp/postBuildingsTagToWeb.sh.25555/modelica-buildings-3.0.0-rc.1/Buildings/Resources/Images/UsersGuide/HydronicHeating.png" border="1"/>
    # in order to update the link.
    with open(tesFil, 'r') as fil:
        lines = fil.readlines()
        for lin in lines:
            iSta = lin.find('Resources/Images/UsersGuide')
            if iSta > -1:
                src_tag = 'src="'
                i_src = lin.find(src_tag)
                if i_src > -1:
                    # entry should be /tmp/postBuildingsTagToWeb.sh.25555/modelica-buildings-3.0.0-rc.1/Buildings
                    entry = lin[i_src+len(src_tag):iSta]
                    replacements[entry] = '../'
                    break

    # Substitute text
    for fil in files:
        filNam = helpDir + os.path.sep + fil
        filObj=open(filNam, 'r')
        lines = filObj.readlines()
        filObj.close()
        for old, new in replacements.iteritems():
            for i in range(len(lines)):
                lines[i] = lines[i].replace(old, new)
                filObj=open(filNam, 'w')
                filObj.writelines(lines)
                filObj.close()

    # Replace certain sections
    for fil in files:
        filNam = helpDir + os.path.sep + fil
        filObj=open(filNam, 'r')
        lines = filObj.readlines()
        filObj.close()
        # Dymola writes
        # <address>
        # <a href="http://www.3ds.com/">Automatically generated</a> Thu Mar 17 16:10:41 2016.
        # </address>
        # This is bad as it gets diff for every file in the version control system.
        # Also, https://www.w3.org/TR/html5/sections.html#the-address-element says there should
        # be nothing else than an address information, i.e., no date.
        # Hence, we change this entry.
        found = False
        for iLin in range(len(lines)-2):
            if "<address>" in lines[iLin].strip() and "</address>" in lines[iLin+2].strip():
                lines[iLin+1] = '''<p></p>
<footer>
<div class="footer">
  <p>
    <a href=\"{homepage}\">{homepage}</a>
  </p>
</div>
</footer>

<!-- Bootstrap core JavaScript
================================================== -->
<!-- Placed at the end of the document so the pages load faster -->
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script>
<script>window.jQuery || document.write('<script src="../Resources/www/js/jquery.min.js"><\/script>')</script>
<script src="../Resources/www/js/bootstrap.min.js"></script>
<!-- IE10 viewport hack for Surface/desktop Windows 8 bug -->
<script src="../Resources/www/js/ie10-viewport-bug-workaround.js"></script>

  </body>

</html>'''.format(homepage = HOMEPAGE)
                found = True
        if found:
            filObj=open(filNam, 'w')
            filObj.writelines(lines)
            filObj.close()

    # Validate the new files
    for fil in files:
        filNam = helpDir + os.path.sep + fil
        # Check if line contains a wrong string
        filObj=open(filNam, 'r')
        for lin in filObj.readlines():
            validateLine(lin, filNam)
            filObj.close()
