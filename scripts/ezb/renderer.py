from ezb import html

from string import Formatter


def tab_for_level(level):
    spaces_per_tab = 2
    return " " * (level * spaces_per_tab)


def tab_format(fmtstr, kwargs, level):
    tab = tab_for_level(level)
    keys = {i[1] for i in Formatter().parse(fmtstr) if i[1] is not None}
    missing_attr = {k for k in keys if kwargs[k] is None}
    if missing_attr:
        print(f"Warning: missing attributes {missing_attr}")
        return None

    new_kwargs = {k: f"\n{tab}".join(kwargs[k].splitlines()) for k in keys}
    return fmtstr.format(**new_kwargs)


def format_tag(tag):
    if tag.startswith("#"):
        return f'<div id="{tag[1:]}">', "</div>"
    return f"<{tag}>", f"</{tag}>"


def subrender(metadata, structure, level=0):
    tab = tab_for_level(level)
    html_lines = []

    if type(structure) is list:
        for el in structure:
            if type(el) is str:
                line = tab_format(el, metadata, level)
                if line is not None:
                    html_lines.append(f"{tab}{line}")
            elif type(el) is dict:
                html_lines.extend(subrender(metadata, el, level=level))
            else:
                raise RuntimeError("Invalid `html.structure` format")
        return html_lines

    for tag, data in structure.items():
        start, end = format_tag(tag)
        html_lines.append(f"{tab}{start}")
        html_lines += subrender(metadata, data, level=level + 1)
        html_lines.append(f"{tab}{end}")

    return html_lines


def render(metadata, body):
    metadata["post_body"] = body
    return '\n'.join(subrender(metadata, html.structure))

