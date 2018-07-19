from ezb import markdown, renderer

def parse_metadata(file):
    metadata = dict.fromkeys([
        "css_file", "title", "thoughts_file", "post_title",
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

