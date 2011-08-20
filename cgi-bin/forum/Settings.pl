####################################################
# E-Blah Bulliten Board Systems               2008 #
####################################################

# IN MOST CASES THIS FILE SHOULDN'T BE EDITED.
# ONLY EDIT IT IF >SETUP< TELLS YOU TO!

# What is the directory that Settings.pl is located in?
$root = ".";

# This should be the only line you need to edit for Avatars, uploads, and templates directories
$bdocsdir2 = "$ENV{'DOCUMENT_ROOT'}/blahdocs";

####################################################
# DO NOT MODIFY ANYTHING BELOW THIS LINE!          #
####################################################

$bversion = 1; # PRE-SETUP Version

# Full DIR to ./{NAME} (Directories; no trailing slash: /)
# If $root is correct, these shouldn't need editing
$code      = "$root/Code";       # Code
$boards    = "$root/Boards";     # Boards
$prefs     = "$root/Prefs";      # Prefs
$members   = "$root/Members";    # Members
$messages  = "$root/Messages";   # Messages
$languages = "$root/Languages";  # Languages
$modsdir   = "$root/Mods";       # Mods Directory

# URL to /blahdocs/{NAME} (URL-Directories; no trailing slash: /)
$images     = "/blahdocs/images";    # images
$buttons    = "/blahdocs/buttons";   # buttons
$simages    = "/blahdocs/Smilies";   # Smilies
$avsurl     = "/blahdocs/Avatars";   # Avatars
$uploadurl  = "/blahdocs/uploads";   # uploads
$templatesu = "/blahdocs/template";  # template
$bdocsdir   = "/blahdocs";           # blahdocs Directory

# Full DIR to the {NAME} directory (Directory; no trailing slash: /)
$avdir     = "$bdocsdir2/Avatars";   # Avatars
$uploaddir = "$bdocsdir2/uploads";   # uploads
$templates = "$bdocsdir2/template";  # template

# HOLY, HOLY, HOLY IS THE LORD GOD ALMIGHTY!
1;