#!/usr/bin/awk -f

BEGIN {
    FS = "/"  # Set field separator to "/" to handle potential path components

    print "# Entity Index\n"
}

/\.html$/ {
    # Get the full filename (last field when split by "/")
    full_filename = $NF
    
    # Remove the .html extension to get the base name
    sub(/\.html$/, "", full_filename)
    
    # Remove the .html extension from the full path as well
    sub(/\.html$/, "", $0)
    
    # Print the Markdown link format
    print "- <a href='" full_filename ".html'>" full_filename "</a>"
}

END {
    if (NR == 0) {
        print "No HTML files found in the current directory."
    }
}
