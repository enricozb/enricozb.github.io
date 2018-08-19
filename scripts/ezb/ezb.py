from ezb import markdown, renderer

import os

from pathlib import Path

def parse_metadata(file):
    metadata = dict.fromkeys([
        "title", "post_title", "post_subtitle",
        "prev_post", "next_post"])

    for line in file:
        if line.strip() == "":
            continue

        words = line.split()
        if words[0].startswith("["):
            key = words[0][1:-1]
            if key == "body":
                break
            if key not in metadata:
                raise RuntimeError(f"Invalid attribute '{key}'")
            metadata[key] =  ' '.join(words[1:])

    num_dirs = len(Path(file.name).parts) - 1
    up_path = "../" * num_dirs
    metadata["css_file"] = f"{up_path}css/main.css"
    metadata["thoughts_file"] = f"{up_path}thoughts"

    if metadata["prev_post"] == "ezb.io/thoughts":
        metadata["prev_post"] = metadata["thoughts_file"]
        metadata["prev_name"] = "Thoughts"
    else:
        metadata["prev_name"] = "Previous"


    if metadata["post_subtitle"] is not None:
        metadata["post_subtitle"] = (
            f'<div id="subtitle">{metadata["post_subtitle"]}</div>')
    else:
        metadata["post_subtitle"] = ""

    return metadata


def parse_body(file):
    body = file.read()
    return markdown.render(body)


def parse(filename):
    with open(filename) as file:
        metadata = parse_metadata(file)
        body = parse_body(file)

    return metadata, body


def to_html(filename):
    metadata, body = parse(filename)
    return renderer.render(metadata, body)
