# table of contents (thoughts) page generator

import hjson
import re
import os

from bs4 import BeautifulSoup as bs


toc_header = """
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="stylesheet" href="css/main.css">
    <title>EZB - Thoughts</title>
  </head>
  <body>
    <a id="home" href="index.html">&larr;</a>
    <div id="maindivalt">
      <div id="title">
        Thoughts
      </div>
      <div id="toc">
"""

toc_footer = """
      </div>
    </div>
  </body>
</html>
"""


def section_html(name):
    return f'<div class="toc-section" id="#{name}">{name}</div>'


def section_end_html():
    return '<div class="toc-section-end">&nbsp;</div>'


def subsection_html(name):
    return f'<div class="toc-subsection">{name}</div>'


def entry_html(name, link, date):
    try:
        future = date == "future"
        if type(date) is list:
            if not os.path.isfile(f"thoughts/{link}"):
                print(f"Warning: linking to non-existent file {link}")
            y, m, d = date
            link_str = f'<a href="thoughts/{link}">{name}</a>'
            date_str = f"{y}.{m:02d}.{d:02d}"
            future_str = ""
        elif future:
            link_str = name
            date_str = "s00n"
            future_str = " future"

        return (f'<div class="toc-entry-n{future_str}">{link_str}</div>\n'
                f'<div class="toc-entry-d{future_str}">{date_str}</div>')
    except:
        raise RuntimeError(f"Entry {entry} has an invalid date.")


def snake_case(s):
    return re.sub('[^0-9a-zA-Z]+', '_', s)


def link_for_entry(section_name, subsection_name, entry_num):
    section = snake_case(section_name.lower())
    subsection = snake_case(subsection_name.lower())
    return f"{section}/{subsection}/{subsection}_{entry_num}.html"


def to_html(filename):
    with open(filename) as input_file:
        thoughts_dict = hjson.load(input_file)

    toc_html = [toc_header]
    for section_name, section in thoughts_dict.items():
        toc_html.append(section_html(section_name))

        for subsection_name, subsection in section.items():
            toc_html.append(subsection_html(subsection_name))

            for i, (entry_name, date) in enumerate(subsection.items()):
                link = link_for_entry(section_name, subsection_name, i + 1)
                toc_html.append(entry_html(entry_name, link, date))

        toc_html.append(section_end_html())

    toc_html.append(toc_footer)

    return bs('\n'.join(toc_html), "html.parser").prettify(formatter="html")

def generate_toc(filename, output_file):
    html = to_html(filename)
    print(f"Generating TOC {output_file}")
    with open(output_file, "w") as outfile:
        outfile.write(html)
        outfile.write("\n")
